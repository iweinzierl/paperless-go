import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';
import 'package:paperless_ngx_app/src/debug/screenshot_harness.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_custom_field.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/selected_document_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

enum _DocumentDetailAction { openOriginal, delete }

class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({
    required this.documentId,
    this.openEditMetadataOnLoad = false,
    this.embedded = false,
    super.key,
  });

  final int documentId;
  final bool openEditMetadataOnLoad;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));
    final isWideScreen = useWideLayout(context);
    final capabilities = ref.watch(currentUserCapabilitiesProvider).valueOrNull;
    final document = documentAsync.valueOrNull;
    final deletingIds = ref.watch(documentDeleteControllerProvider);
    final isDeleting = deletingIds.contains(documentId);
    final canSeeDeleteAction =
        document != null &&
        capabilities != null &&
        capabilities.hasPermission('delete_document');
    final canDeleteDocument =
        document != null &&
        capabilities != null &&
        document.canBeDeletedBy(capabilities);

    final documentActions = document == null
        ? const <Widget>[]
        : isDeleting
        ? const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ]
        : [
            PopupMenuButton<_DocumentDetailAction>(
              onSelected: (action) {
                switch (action) {
                  case _DocumentDetailAction.openOriginal:
                    _openOriginalDocument(context, ref, document);
                  case _DocumentDetailAction.delete:
                    _deleteDocument(context, ref, document, embedded);
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<_DocumentDetailAction>>[
                  PopupMenuItem<_DocumentDetailAction>(
                    value: _DocumentDetailAction.openOriginal,
                    child: Text(context.l10n.openOriginalAction),
                  ),
                ];

                if (canSeeDeleteAction) {
                  items.add(
                    PopupMenuItem<_DocumentDetailAction>(
                      value: _DocumentDetailAction.delete,
                      enabled: canDeleteDocument,
                      child: Text(context.l10n.deleteDocumentAction),
                    ),
                  );
                }

                return items;
              },
            ),
          ];

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: embedded
          ? null
          : AppBar(
              title: Text(
                isWideScreen
                    ? context.l10n.documentDetailsTitle
                    : (document?.title ?? context.l10n.documentDetailsTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: documentActions,
            ),
      body: documentAsync.when(
        data: (document) => _DocumentDetailBody(
          document: document,
          openEditMetadataOnLoad: openEditMetadataOnLoad,
          embedded: embedded,
          actionWidgets: documentActions,
        ),
        error: (error, stackTrace) => _DocumentDetailError(
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _openOriginalDocument(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
  ) async {
    try {
      ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
      await ref
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document, original: true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteDocument(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
    bool embedded,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteDocumentAction),
        content: Text(
          dialogContext.l10n.deleteDocumentConfirmationMessage(document.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref
          .read(documentDeleteControllerProvider.notifier)
          .deleteDocument(document);

      if (!context.mounted) {
        return;
      }

      if (embedded) {
        ref.read(selectedDocumentIdProvider.notifier).state = null;
      } else {
        navigator.pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.documentDeleted)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _DocumentDetailBody extends ConsumerStatefulWidget {
  const _DocumentDetailBody({
    required this.document,
    required this.openEditMetadataOnLoad,
    required this.embedded,
    required this.actionWidgets,
  });

  final PaperlessDocument document;
  final bool openEditMetadataOnLoad;
  final bool embedded;
  final List<Widget> actionWidgets;

  @override
  ConsumerState<_DocumentDetailBody> createState() =>
      _DocumentDetailBodyState();
}

class _DocumentDetailBodyState extends ConsumerState<_DocumentDetailBody> {
  int _selectedPage = 1;
  late final ScrollController _pageStripScrollController;
  bool _didAutoOpenMetadataEditor = false;
  _ScreenshotPreviewState _previewState = _ScreenshotPreviewState.loading;

  @override
  void initState() {
    super.initState();
    _pageStripScrollController = ScrollController();
    _scheduleMetadataEditorOpen();
  }

  @override
  void didUpdateWidget(covariant _DocumentDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openEditMetadataOnLoad != widget.openEditMetadataOnLoad ||
        oldWidget.document.id != widget.document.id) {
      _didAutoOpenMetadataEditor = false;
      _scheduleMetadataEditorOpen();
    }

    if (oldWidget.document.id != widget.document.id) {
      _selectedPage = 1;
      _previewState = _ScreenshotPreviewState.loading;
      if (_pageStripScrollController.hasClients) {
        _pageStripScrollController.jumpTo(0);
      }
      return;
    }

    final maxPage = widget.document.pageCount ?? 1;
    if (_selectedPage > maxPage) {
      _selectedPage = maxPage;
    }
  }

  @override
  void dispose() {
    _pageStripScrollController.dispose();
    super.dispose();
  }

  void _scheduleMetadataEditorOpen() {
    if (!widget.openEditMetadataOnLoad || _didAutoOpenMetadataEditor) {
      return;
    }

    _didAutoOpenMetadataEditor = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _editMetadata(context, ref, widget.document);
    });
  }

  void _updatePreviewState(_ScreenshotPreviewState state) {
    if (!mounted || _previewState == state) {
      return;
    }

    setState(() {
      _previewState = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final openingIds = ref.watch(documentOpenControllerProvider);
    final capabilities = ref.watch(currentUserCapabilitiesProvider).valueOrNull;
    final isOpening = openingIds.contains(document.id);
    final canEditMetadata =
        capabilities != null && document.canBeChangedBy(capabilities);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final repository = ref.watch(documentsRepositoryProvider);
    final isScreenshotScenario =
        ref
            .read(sharedPreferencesProvider)
            .getString(screenshotScenarioPreferenceKey) !=
        null;
    final thumbnailWidget = repository.buildDocumentThumbnailWidget(document);
    final thumbnailImageProvider = repository
        .buildDocumentThumbnailImageProvider(document.id);
    final effectivePageCount = document.pageCount ?? 1;
    final selectedPage = _selectedPage > effectivePageCount
        ? effectivePageCount
        : _selectedPage;
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final tagOptions = ref.watch(tagOptionsProvider);
    final customFieldDefinitions = document.customFields.isEmpty
        ? const AsyncValue<List<PaperlessCustomField>>.data(
            <PaperlessCustomField>[],
          )
        : ref.watch(customFieldDefinitionsProvider);
    final correspondentName = _resolveOptionName(
      correspondentOptions,
      document.correspondentId,
    );
    final documentTypeName = _resolveOptionName(
      documentTypeOptions,
      document.documentTypeId,
    );
    final tagNames = _resolveTagNames(tagOptions, document.tags);
    final summaryLeadingLabel = correspondentName ?? l10n.noCorrespondentOption;
    final summaryTrailingLabel = _formatMetadataTimestamp(
      context,
      document.created,
    );
    final summaryBadges = <String>[
      if (documentTypeName != null) documentTypeName,
      ...tagNames,
    ];

    return _ScreenshotPreviewStateMarker(
      state: _previewState,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (widget.embedded) ...[
                  _EmbeddedDocumentActionBar(
                    title: document.title,
                    actionWidgets: widget.actionWidgets,
                  ),
                  const SizedBox(height: 16),
                ],
                _DocumentSummaryCard(
                  primaryLabel: summaryLeadingLabel,
                  trailingLabel: summaryTrailingLabel,
                  badges: summaryBadges,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: isOpening
                      ? null
                      : () => _openDocument(context, ref, document),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icon(
                    isOpening ? Icons.hourglass_top : Icons.visibility_outlined,
                  ),
                  label: Text(
                    isOpening ? l10n.openingAction : l10n.openDocumentAction,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: canEditMetadata
                      ? () => _editMetadata(context, ref, document)
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editMetadataAction),
                ),
                const SizedBox(height: 16),
                _PreviewCard(
                  title: l10n.thumbnailPreviewTitle,
                  document: document,
                  pageCount: effectivePageCount,
                  selectedPage: selectedPage,
                  preferFallbackWhileLoading: isScreenshotScenario,
                  pageStripScrollController: _pageStripScrollController,
                  thumbnailWidget: thumbnailWidget,
                  thumbnailImageProvider: thumbnailImageProvider,
                  repository: repository,
                  onPreviewStateChanged: _updatePreviewState,
                  onSelectPage: (pageNumber) {
                    if (pageNumber == _selectedPage) {
                      return;
                    }
                    setState(() {
                      _selectedPage = pageNumber;
                    });
                  },
                  onPreview: isOpening
                      ? null
                      : () => _openFullscreenPreview(
                          context,
                          document,
                          initialPage: selectedPage,
                        ),
                ),
                const SizedBox(height: 16),
                useWideLayout(context)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _MetadataCard(
                              title: l10n.metadataTitle,
                              children: [
                                _MetadataInfoRow(
                                  label: l10n.fileNameLabel,
                                  value: document.preferredFileName,
                                ),
                                _MetadataInfoRow(
                                  label: l10n.mimeTypeLabel,
                                  value: document.mimeType,
                                ),
                                _MetadataInfoRow(
                                  label: l10n.createdLabel,
                                  value: _formatMetadataTimestamp(
                                    context,
                                    document.created,
                                  ),
                                ),
                                _MetadataInfoRow(
                                  label: l10n.pagesLabel,
                                  value: document.pageCount?.toString(),
                                ),
                                _MetadataInfoRow(
                                  label: l10n.archiveSerialNumberLabel,
                                  value: document.archiveSerialNumber
                                      ?.toString(),
                                ),
                                _ResolvedOptionRow(
                                  label: l10n.correspondentLabel,
                                  optionId: document.correspondentId,
                                  options: correspondentOptions,
                                  fallbackValue: document.correspondentId
                                      ?.toString(),
                                ),
                                _ResolvedOptionRow(
                                  label: l10n.documentTypeLabel,
                                  optionId: document.documentTypeId,
                                  options: documentTypeOptions,
                                  fallbackValue: document.documentTypeId
                                      ?.toString(),
                                ),
                                _ResolvedCustomFieldsRows(
                                  document: document,
                                  definitions: customFieldDefinitions,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _MetadataCard(
                              title: l10n.tagsLabel,
                              children: [
                                _ResolvedTagsRow(
                                  document: document,
                                  options: tagOptions,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _MetadataCard(
                        title: l10n.metadataTitle,
                        children: [
                          _MetadataInfoRow(
                            label: l10n.fileNameLabel,
                            value: document.preferredFileName,
                          ),
                          _MetadataInfoRow(
                            label: l10n.mimeTypeLabel,
                            value: document.mimeType,
                          ),
                          _MetadataInfoRow(
                            label: l10n.createdLabel,
                            value: _formatMetadataTimestamp(
                              context,
                              document.created,
                            ),
                          ),
                          _MetadataInfoRow(
                            label: l10n.pagesLabel,
                            value: document.pageCount?.toString(),
                          ),
                          _MetadataInfoRow(
                            label: l10n.archiveSerialNumberLabel,
                            value: document.archiveSerialNumber?.toString(),
                          ),
                          _ResolvedOptionRow(
                            label: l10n.correspondentLabel,
                            optionId: document.correspondentId,
                            options: correspondentOptions,
                            fallbackValue: document.correspondentId?.toString(),
                          ),
                          _ResolvedOptionRow(
                            label: l10n.documentTypeLabel,
                            optionId: document.documentTypeId,
                            options: documentTypeOptions,
                            fallbackValue: document.documentTypeId?.toString(),
                          ),
                          _ResolvedTagsRow(
                            document: document,
                            options: tagOptions,
                          ),
                          _ResolvedCustomFieldsRows(
                            document: document,
                            definitions: customFieldDefinitions,
                          ),
                        ],
                      ),
                if (document.content != null &&
                    document.content!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: l10n.contentPreviewTitle,
                    children: [
                      Text(
                        document.content!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document, {
    bool original = false,
    DocumentOpenVariant variant = DocumentOpenVariant.download,
  }) async {
    try {
      ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
      await ref
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document, original: original, variant: variant);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _editMetadata(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
  ) async {
    final updatedDocument = await Navigator.of(context).push<PaperlessDocument>(
      MaterialPageRoute<PaperlessDocument>(
        builder: (context) => _EditDocumentMetadataPage(document: document),
      ),
    );

    if (updatedDocument == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.metadataUpdated)));
  }

  Future<void> _openFullscreenPreview(
    BuildContext context,
    PaperlessDocument document, {
    required int initialPage,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _DocumentFullscreenPreviewPage(
          document: document,
          initialPage: initialPage,
        ),
      ),
    );
  }
}

class _EmbeddedDocumentActionBar extends StatelessWidget {
  const _EmbeddedDocumentActionBar({
    required this.title,
    required this.actionWidgets,
  });

  final String title;
  final List<Widget> actionWidgets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...actionWidgets,
        ],
      ),
    );
  }
}

String? _resolveOptionName(
  AsyncValue<List<PaperlessFilterOption>> options,
  int? id,
) {
  if (id == null) {
    return null;
  }

  return options.maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.id == id) {
          return item.name;
        }
      }
      return null;
    },
    orElse: () => null,
  );
}

List<String> _resolveTagNames(
  AsyncValue<List<PaperlessFilterOption>> options,
  List<int> ids,
) {
  if (ids.isEmpty) {
    return const <String>[];
  }

  return options.maybeWhen(
    data: (items) {
      final namesById = <int, String>{
        for (final item in items) item.id: item.name,
      };
      return ids
          .map((id) => namesById[id])
          .whereType<String>()
          .toList(growable: false);
    },
    orElse: () => const <String>[],
  );
}

class _EditDocumentMetadataPage extends ConsumerStatefulWidget {
  const _EditDocumentMetadataPage({required this.document});

  final PaperlessDocument document;

  @override
  ConsumerState<_EditDocumentMetadataPage> createState() =>
      _EditDocumentMetadataPageState();
}

class _EditDocumentMetadataPageState
    extends ConsumerState<_EditDocumentMetadataPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _createdController;
  late final Map<int, Object?> _selectedCustomFieldValues;
  final Map<int, TextEditingController> _customFieldControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _customFieldCurrencyControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _customFieldAmountControllers =
      <int, TextEditingController>{};
  Map<int, String> _customFieldErrors = <int, String>{};
  late int? _selectedCorrespondentId;
  late int? _selectedDocumentTypeId;
  late Set<int> _selectedTagIds;
  int _selectedPreviewPage = 1;
  _ScreenshotPreviewState _previewState = _ScreenshotPreviewState.loading;
  bool _hasSubmitted = false;
  bool _isSaving = false;
  bool _isCreatingCorrespondent = false;
  bool _isCreatingDocumentType = false;

  bool get _isMutatingOptions =>
      _isCreatingCorrespondent || _isCreatingDocumentType;

  bool get _isBusy => _isSaving || _isMutatingOptions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _createdController = TextEditingController(
      text: _initialCreatedValue(widget.document.created),
    );
    _selectedCorrespondentId = widget.document.correspondentId;
    _selectedDocumentTypeId = widget.document.documentTypeId;
    _selectedTagIds = widget.document.tags.toSet();
    _selectedCustomFieldValues = <int, Object?>{
      for (final customField in widget.document.customFields)
        customField.field: customField.value,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _createdController.dispose();
    for (final controller in _customFieldControllers.values) {
      controller.dispose();
    }
    for (final controller in _customFieldCurrencyControllers.values) {
      controller.dispose();
    }
    for (final controller in _customFieldAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? get _titleError {
    if (!_hasSubmitted) {
      return null;
    }

    if (_titleController.text.trim().isEmpty) {
      return context.l10n.enterNameValidation;
    }

    return null;
  }

  String? get _createdError {
    if (!_hasSubmitted) {
      return null;
    }

    final trimmed = _createdController.text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (DateTime.tryParse(trimmed) == null) {
      return context.l10n.invalidDateValidation;
    }

    return null;
  }

  bool get _isValid => _titleError == null && _createdError == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isWideScreen = useWideLayout(context);
    final repository = ref.watch(documentsRepositoryProvider);
    final correspondents = ref.watch(correspondentOptionsProvider);
    final documentTypes = ref.watch(documentTypeOptionsProvider);
    final tags = ref.watch(tagOptionsProvider);
    final customFieldDefinitions = ref.watch(customFieldDefinitionsProvider);
    final selectedCorrespondentLabel = correspondents.maybeWhen(
      data: (items) => items
          .where((item) => item.id == _selectedCorrespondentId)
          .firstOrNull
          ?.name,
      orElse: () => _selectedCorrespondentId == null
          ? null
          : '#$_selectedCorrespondentId',
    );
    final selectedDocumentTypeLabel = documentTypes.maybeWhen(
      data: (items) => items
          .where((item) => item.id == _selectedDocumentTypeId)
          .firstOrNull
          ?.name,
      orElse: () =>
          _selectedDocumentTypeId == null ? null : '#$_selectedDocumentTypeId',
    );
    final selectedTagLabels = <int, String>{
      for (final tagId in _selectedTagIds) tagId: '#$tagId',
    };
    tags.maybeWhen(
      data: (items) {
        for (final item in items) {
          if (_selectedTagIds.contains(item.id)) {
            selectedTagLabels[item.id] = item.name;
          }
        }
      },
      orElse: () {},
    );
    final selectedTags = selectedTagLabels.entries.toList()
      ..sort(
        (left, right) =>
            left.value.toLowerCase().compareTo(right.value.toLowerCase()),
      );
    final heroBadges = <String>[
      if (widget.document.mimeType?.trim().isNotEmpty == true)
        widget.document.mimeType!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editMetadataTitle),
        actions: [
          if (isWideScreen)
            TextButton(
              onPressed: _isBusy
                  ? null
                  : () => Navigator.of(context).maybePop(),
              child: Text(l10n.cancelAction),
            ),
          TextButton(
            onPressed: _isBusy ? null : _save,
            child: Text(_isSaving ? l10n.savingAction : l10n.saveAction),
          ),
        ],
      ),
      body: _ScreenshotPreviewStateMarker(
        state: _previewState,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: theme.colorScheme.surface,
              child: isWideScreen
                  ? _buildWideMetadataEditor(
                      context,
                      theme,
                      l10n,
                      repository,
                      correspondents,
                      documentTypes,
                      tags,
                      customFieldDefinitions,
                      selectedCorrespondentLabel,
                      selectedDocumentTypeLabel,
                      selectedTags,
                      heroBadges,
                    )
                  : _buildCompactMetadataEditor(
                      context,
                      theme,
                      l10n,
                      repository,
                      correspondents,
                      documentTypes,
                      tags,
                      customFieldDefinitions,
                      selectedCorrespondentLabel,
                      selectedDocumentTypeLabel,
                      selectedTags,
                      heroBadges,
                    ),
            ),
            const IgnorePointer(
              child: Opacity(
                opacity: 0,
                alwaysIncludeSemantics: true,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('paperless-screenshot-state-ready'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetadataEditor(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DocumentsRepository repository,
    AsyncValue<List<PaperlessFilterOption>> correspondents,
    AsyncValue<List<PaperlessFilterOption>> documentTypes,
    AsyncValue<List<PaperlessFilterOption>> tags,
    AsyncValue<List<PaperlessCustomField>> customFieldDefinitions,
    String? selectedCorrespondentLabel,
    String? selectedDocumentTypeLabel,
    List<MapEntry<int, String>> selectedTags,
    List<String> heroBadges,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            ..._buildBasicInfoFields(l10n),
            const SizedBox(height: 16),
            _buildCompactCorrespondentField(
              l10n,
              correspondents,
              selectedCorrespondentLabel,
            ),
            const SizedBox(height: 16),
            _buildCompactDocumentTypeField(
              l10n,
              documentTypes,
              selectedDocumentTypeLabel,
            ),
            const SizedBox(height: 16),
            _buildCompactTagsField(context, theme, l10n, tags, selectedTags),
            const SizedBox(height: 16),
            _buildCompactCustomFieldsSection(
              theme,
              l10n,
              customFieldDefinitions,
            ),
            const SizedBox(height: 20),
            _EditMetadataHero(
              document: widget.document,
              repository: repository,
              selectedPage: _selectedPreviewPage,
              onPreviewStateChanged: _updatePreviewState,
              onSelectPage: (pageNumber) {
                final pageCount = widget.document.pageCount ?? 1;
                setState(() {
                  _selectedPreviewPage = pageNumber.clamp(1, pageCount);
                });
              },
              badges: heroBadges,
            ),
            const SizedBox(height: 20),
            Text(
              'End of archive metadata',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideMetadataEditor(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    DocumentsRepository repository,
    AsyncValue<List<PaperlessFilterOption>> correspondents,
    AsyncValue<List<PaperlessFilterOption>> documentTypes,
    AsyncValue<List<PaperlessFilterOption>> tags,
    AsyncValue<List<PaperlessCustomField>> customFieldDefinitions,
    String? selectedCorrespondentLabel,
    String? selectedDocumentTypeLabel,
    List<MapEntry<int, String>> selectedTags,
    List<String> heroBadges,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewWidth = constraints.maxWidth >= 1200 ? 500.0 : 420.0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 24, bottom: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EditSectionCard(
                            child: Column(
                              children: _buildBasicInfoFields(l10n),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _EditSectionCard(
                            child: Column(
                              children: [
                                _buildWideCorrespondentField(
                                  l10n,
                                  correspondents,
                                  selectedCorrespondentLabel,
                                ),
                                const SizedBox(height: 16),
                                _buildWideDocumentTypeField(
                                  l10n,
                                  documentTypes,
                                  selectedDocumentTypeLabel,
                                ),
                                const SizedBox(height: 16),
                                _buildWideTagsField(
                                  context,
                                  theme,
                                  l10n,
                                  tags,
                                  selectedTags,
                                ),
                                const SizedBox(height: 16),
                                _buildWideCustomFieldsSection(
                                  l10n,
                                  customFieldDefinitions,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: previewWidth,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.thumbnailPreviewTitle,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _EditMetadataHero(
                          document: widget.document,
                          repository: repository,
                          selectedPage: _selectedPreviewPage,
                          onPreviewStateChanged: _updatePreviewState,
                          onSelectPage: (pageNumber) {
                            final pageCount = widget.document.pageCount ?? 1;
                            setState(() {
                              _selectedPreviewPage = pageNumber.clamp(
                                1,
                                pageCount,
                              );
                            });
                          },
                          badges: heroBadges,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBasicInfoFields(AppLocalizations l10n) {
    return [
      _EditFieldSection(
        label: l10n.titleLabel,
        child: _EditMetadataTextField(
          controller: _titleController,
          enabled: !_isBusy,
          hintText: l10n.titleLabel,
          textInputAction: TextInputAction.next,
          errorText: _titleError,
        ),
      ),
      const SizedBox(height: 18),
      _EditFieldSection(
        label: l10n.createdDateLabel,
        child: _EditMetadataTextField(
          controller: _createdController,
          enabled: !_isBusy,
          hintText: l10n.createdDateHint,
          keyboardType: TextInputType.datetime,
          errorText: _createdError,
          suffix: IconButton(
            onPressed: _isBusy ? null : _pickCreatedDate,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ),
      ),
    ];
  }

  Widget _buildCompactCorrespondentField(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> correspondents,
    String? selectedCorrespondentLabel,
  ) {
    return _EditFieldSection(
      label: l10n.correspondentLabel,
      child: correspondents.when(
        data: (items) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _EditSelectionField(
                icon: Icons.business_outlined,
                value: selectedCorrespondentLabel,
                placeholder: l10n.noCorrespondentOption,
                actionIcon: Icons.unfold_more,
                enabled: !_isBusy,
                onTap: _isBusy
                    ? null
                    : () => _openCorrespondentSelection(items),
              ),
            ),
            const SizedBox(width: 12),
            _EditSquareActionButton(
              icon: _isCreatingCorrespondent ? null : Icons.add_rounded,
              onTap: _isBusy || _isCreatingCorrespondent
                  ? null
                  : _createCorrespondent,
              isLoading: _isCreatingCorrespondent,
            ),
          ],
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.couldNotLoadCorrespondents,
          isError: true,
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildCompactDocumentTypeField(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> documentTypes,
    String? selectedDocumentTypeLabel,
  ) {
    return _EditFieldSection(
      label: l10n.documentTypeLabel,
      child: documentTypes.when(
        data: (items) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _EditSelectionField(
                icon: Icons.description_outlined,
                value: selectedDocumentTypeLabel,
                placeholder: l10n.noDocumentTypeOption,
                actionIcon: Icons.unfold_more,
                enabled: !_isBusy,
                onTap: _isBusy ? null : () => _openDocumentTypeSelection(items),
              ),
            ),
            const SizedBox(width: 12),
            _EditSquareActionButton(
              icon: _isCreatingDocumentType ? null : Icons.add_rounded,
              onTap: _isBusy || _isCreatingDocumentType
                  ? null
                  : _createDocumentType,
              isLoading: _isCreatingDocumentType,
            ),
          ],
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.couldNotLoadDocumentTypes,
          isError: true,
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildCompactTagsField(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> tags,
    List<MapEntry<int, String>> selectedTags,
  ) {
    return _EditFieldSection(
      label: l10n.tagsLabel,
      child: tags.when(
        data: (items) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: selectedTags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        l10n.noTagsSelected,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final tag in selectedTags)
                          _EditSelectionChip(
                            label: tag.value,
                            icon: Icons.sell_outlined,
                            selected: true,
                            enabled: !_isBusy,
                            onPressed: _isBusy
                                ? null
                                : () => _openTagSelection(items),
                            onDeleted: _isBusy
                                ? null
                                : () => _removeSelectedTag(tag.key),
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            _EditSquareActionButton(
              icon: Icons.add_rounded,
              onTap: _isBusy ? null : () => _openTagSelection(items),
              isLoading: false,
            ),
          ],
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.retryTagLoadingAction,
          isError: true,
          actionLabel: l10n.retryAction,
          onAction: _isBusy ? null : () => ref.invalidate(tagOptionsProvider),
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildWideCorrespondentField(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> correspondents,
    String? selectedCorrespondentLabel,
  ) {
    return _EditFieldSection(
      label: l10n.correspondentLabel,
      trailing: TextButton.icon(
        onPressed: _isBusy || _isCreatingCorrespondent
            ? null
            : _createCorrespondent,
        icon: _isCreatingCorrespondent
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: Text(l10n.newCorrespondentAction),
      ),
      child: correspondents.when(
        data: (items) => _EditSelectionField(
          icon: Icons.business_outlined,
          value: selectedCorrespondentLabel,
          placeholder: l10n.noCorrespondentOption,
          actionIcon: Icons.unfold_more,
          enabled: !_isBusy,
          onTap: _isBusy ? null : () => _openCorrespondentSelection(items),
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.couldNotLoadCorrespondents,
          isError: true,
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildWideDocumentTypeField(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> documentTypes,
    String? selectedDocumentTypeLabel,
  ) {
    return _EditFieldSection(
      label: l10n.documentTypeLabel,
      trailing: TextButton.icon(
        onPressed: _isBusy || _isCreatingDocumentType
            ? null
            : _createDocumentType,
        icon: _isCreatingDocumentType
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: Text(l10n.newDocumentTypeAction),
      ),
      child: documentTypes.when(
        data: (items) => _EditSelectionField(
          icon: Icons.description_outlined,
          value: selectedDocumentTypeLabel,
          placeholder: l10n.noDocumentTypeOption,
          actionIcon: Icons.unfold_more,
          enabled: !_isBusy,
          onTap: _isBusy ? null : () => _openDocumentTypeSelection(items),
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.couldNotLoadDocumentTypes,
          isError: true,
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildWideTagsField(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> tags,
    List<MapEntry<int, String>> selectedTags,
  ) {
    return _EditFieldSection(
      label: l10n.tagsLabel,
      trailing: TextButton.icon(
        onPressed: _isBusy ? null : _createTag,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newTagAction),
      ),
      child: tags.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditSelectionField(
              icon: Icons.sell_outlined,
              value: selectedTags.isEmpty ? null : l10n.tagsLabel,
              placeholder: l10n.noTagsSelected,
              actionIcon: Icons.unfold_more,
              enabled: !_isBusy,
              onTap: _isBusy ? null : () => _openTagSelection(items),
            ),
            if (selectedTags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tag in selectedTags)
                    _EditSelectionChip(
                      label: tag.value,
                      icon: Icons.sell_outlined,
                      selected: true,
                      enabled: !_isBusy,
                      onPressed: _isBusy
                          ? null
                          : () => _openTagSelection(items),
                      onDeleted: _isBusy
                          ? null
                          : () => _removeSelectedTag(tag.key),
                    ),
                ],
              ),
            ],
          ],
        ),
        error: (error, stackTrace) => _EditInlineStatusCard(
          message: l10n.retryTagLoadingAction,
          isError: true,
          actionLabel: l10n.retryAction,
          onAction: _isBusy ? null : () => ref.invalidate(tagOptionsProvider),
        ),
        loading: () => const _EditLoadingCard(),
      ),
    );
  }

  Widget _buildCompactCustomFieldsSection(
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<List<PaperlessCustomField>> definitions,
  ) {
    return _EditFieldSection(
      label: l10n.customFieldsLabel,
      trailing: TextButton.icon(
        onPressed: _isBusy
            ? null
            : () {
                final values = definitions.valueOrNull;
                if (values != null) {
                  _openCustomFieldSelection(values);
                }
              },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addCustomFieldAction),
      ),
      child: _buildCustomFieldsEditorBody(theme, l10n, definitions),
    );
  }

  Widget _buildWideCustomFieldsSection(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessCustomField>> definitions,
  ) {
    return _EditFieldSection(
      label: l10n.customFieldsLabel,
      trailing: TextButton.icon(
        onPressed: _isBusy
            ? null
            : () {
                final values = definitions.valueOrNull;
                if (values != null) {
                  _openCustomFieldSelection(values);
                }
              },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addCustomFieldAction),
      ),
      child: _buildCustomFieldsEditorBody(Theme.of(context), l10n, definitions),
    );
  }

  Widget _buildCustomFieldsEditorBody(
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<List<PaperlessCustomField>> definitions,
  ) {
    return definitions.when(
      data: (items) {
        final selectedIds = _selectedCustomFieldValues.keys.toSet();
        final selectedDefinitions =
            items
                .where((item) => selectedIds.contains(item.id))
                .toList(growable: false)
              ..sort((left, right) => left.name.compareTo(right.name));

        if (selectedDefinitions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              l10n.noCustomFieldsAssigned,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (
              var index = 0;
              index < selectedDefinitions.length;
              index++
            ) ...[
              _buildCustomFieldEditor(selectedDefinitions[index]),
              if (index < selectedDefinitions.length - 1)
                const SizedBox(height: 18),
            ],
          ],
        );
      },
      error: (error, stackTrace) => _EditInlineStatusCard(
        message: l10n.couldNotLoadCustomFields,
        isError: true,
      ),
      loading: () => const _EditLoadingCard(),
    );
  }

  Widget _buildCustomFieldEditor(PaperlessCustomField definition) {
    final value = _selectedCustomFieldValues[definition.id];
    final errorText = _customFieldErrors[definition.id];

    return _EditFieldSection(
      label: definition.name,
      trailing: TextButton.icon(
        onPressed: _isBusy ? null : () => _removeCustomField(definition.id),
        icon: const Icon(Icons.remove_circle_outline_rounded),
        label: Text(context.l10n.removeCustomFieldAction),
      ),
      child: switch (definition.dataType) {
        PaperlessCustomFieldDataType.boolean => SwitchListTile.adaptive(
          value: value is bool ? value : false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            value == true
                ? context.l10n.customFieldBooleanTrue
                : context.l10n.customFieldBooleanFalse,
          ),
          onChanged: _isBusy
              ? null
              : (next) => _setCustomFieldValue(definition.id, next),
        ),
        PaperlessCustomFieldDataType.select => _buildSelectCustomFieldEditor(
          definition,
          value,
          errorText,
        ),
        PaperlessCustomFieldDataType.monetary =>
          _buildMonetaryCustomFieldEditor(definition, value, errorText),
        _ => _buildTextCustomFieldEditor(definition, value, errorText),
      },
    );
  }

  Widget _buildMonetaryCustomFieldEditor(
    PaperlessCustomField definition,
    Object? value,
    String? errorText,
  ) {
    final monetaryValue = _monetaryValueForCustomField(
      fieldId: definition.id,
      value: value,
      defaultCurrency: definition.defaultCurrency,
    );
    final currencyController = _currencyControllerForCustomField(
      definition.id,
      monetaryValue,
    );
    final amountController = _amountControllerForCustomField(
      definition.id,
      monetaryValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: _EditMetadataTextField(
                controller: currencyController,
                enabled: !_isBusy,
                hintText: context.l10n.customFieldCurrencyHint,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EditMetadataTextField(
                controller: amountController,
                enabled: !_isBusy,
                hintText: context.l10n.customFieldAmountHint,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectCustomFieldEditor(
    PaperlessCustomField definition,
    Object? value,
    String? errorText,
  ) {
    final selectedId = value?.toString();
    final selectedOption = definition.selectOptions
        .where((item) => item.id == selectedId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditSelectionField(
          icon: Icons.tune_rounded,
          value: selectedOption?.label,
          placeholder: context.l10n.customFieldNoValueOption,
          actionIcon: Icons.unfold_more,
          enabled: !_isBusy,
          onTap: _isBusy ? null : () => _openCustomSelectOption(definition),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextCustomFieldEditor(
    PaperlessCustomField definition,
    Object? value,
    String? errorText,
  ) {
    final controller = _controllerForCustomField(
      definition.id,
      value,
      definition,
    );

    return _EditMetadataTextField(
      controller: controller,
      enabled: !_isBusy,
      hintText: _customFieldHint(definition.dataType),
      keyboardType: _customFieldKeyboardType(definition.dataType),
      textInputAction: TextInputAction.next,
      errorText: errorText,
    );
  }

  TextEditingController _controllerForCustomField(
    int fieldId,
    Object? value, [
    PaperlessCustomField? definition,
  ]) {
    final existing = _customFieldControllers[fieldId];
    if (existing != null) {
      return existing;
    }

    final controller = TextEditingController(
      text: _editorValueForCustomField(value, definition),
    );
    controller.addListener(() {
      _selectedCustomFieldValues[fieldId] = controller.text;
      if (_customFieldErrors.containsKey(fieldId)) {
        setState(() {
          _customFieldErrors = Map<int, String>.from(_customFieldErrors)
            ..remove(fieldId);
        });
      }
    });
    _customFieldControllers[fieldId] = controller;
    return controller;
  }

  TextEditingController _currencyControllerForCustomField(
    int fieldId,
    _MonetaryCustomFieldValue value,
  ) {
    final existing = _customFieldCurrencyControllers[fieldId];
    if (existing != null) {
      return existing;
    }

    final controller = TextEditingController(text: value.currency);
    controller.addListener(() {
      _selectedCustomFieldValues[fieldId] = _MonetaryCustomFieldValue(
        currency: controller.text,
        amount: _customFieldAmountControllers[fieldId]?.text ?? value.amount,
      );
      if (_customFieldErrors.containsKey(fieldId)) {
        setState(() {
          _customFieldErrors = Map<int, String>.from(_customFieldErrors)
            ..remove(fieldId);
        });
      }
    });
    _customFieldCurrencyControllers[fieldId] = controller;
    return controller;
  }

  TextEditingController _amountControllerForCustomField(
    int fieldId,
    _MonetaryCustomFieldValue value,
  ) {
    final existing = _customFieldAmountControllers[fieldId];
    if (existing != null) {
      return existing;
    }

    final localizedAmount = _formatLocalizedNumericString(
      context,
      value.amount,
    );
    final controller = TextEditingController(text: localizedAmount);
    controller.addListener(() {
      _selectedCustomFieldValues[fieldId] = _MonetaryCustomFieldValue(
        currency:
            _customFieldCurrencyControllers[fieldId]?.text ?? value.currency,
        amount: controller.text,
      );
      if (_customFieldErrors.containsKey(fieldId)) {
        setState(() {
          _customFieldErrors = Map<int, String>.from(_customFieldErrors)
            ..remove(fieldId);
        });
      }
    });
    _customFieldAmountControllers[fieldId] = controller;
    return controller;
  }

  _MonetaryCustomFieldValue _monetaryValueForCustomField({
    required int fieldId,
    required Object? value,
    required String? defaultCurrency,
  }) {
    final currentValue = _selectedCustomFieldValues[fieldId];
    if (currentValue is _MonetaryCustomFieldValue) {
      return currentValue;
    }

    final parsed = _parseMonetaryCustomFieldValue(value, defaultCurrency);
    final normalized = _MonetaryCustomFieldValue(
      currency: parsed.currency,
      amount: parsed.amount,
    );
    _selectedCustomFieldValues[fieldId] = normalized;
    return normalized;
  }

  String _stringValueForCustomField(Object? value) {
    if (value == null) {
      return '';
    }

    if (value is List) {
      return value.map((item) => item.toString()).join(',');
    }

    return value.toString();
  }

  String _editorValueForCustomField(
    Object? value,
    PaperlessCustomField? definition,
  ) {
    if (definition == null) {
      return _stringValueForCustomField(value);
    }

    return switch (definition.dataType) {
      PaperlessCustomFieldDataType.integer ||
      PaperlessCustomFieldDataType.float => _formatLocalizedNumericString(
        context,
        value?.toString() ?? '',
      ),
      _ => _stringValueForCustomField(value),
    };
  }

  String _customFieldHint(PaperlessCustomFieldDataType dataType) {
    return switch (dataType) {
      PaperlessCustomFieldDataType.url => context.l10n.customFieldUrlHint,
      PaperlessCustomFieldDataType.date => context.l10n.customFieldDateHint,
      PaperlessCustomFieldDataType.integer =>
        context.l10n.customFieldIntegerHint,
      PaperlessCustomFieldDataType.float => context.l10n.customFieldFloatHint,
      PaperlessCustomFieldDataType.monetary =>
        context.l10n.customFieldMonetaryHint,
      PaperlessCustomFieldDataType.documentLink =>
        context.l10n.customFieldDocumentLinkHint,
      PaperlessCustomFieldDataType.longText =>
        context.l10n.customFieldLongTextHint,
      _ => context.l10n.customFieldGenericHint,
    };
  }

  TextInputType? _customFieldKeyboardType(
    PaperlessCustomFieldDataType dataType,
  ) {
    return switch (dataType) {
      PaperlessCustomFieldDataType.url => TextInputType.url,
      PaperlessCustomFieldDataType.date => TextInputType.datetime,
      PaperlessCustomFieldDataType.integer => TextInputType.number,
      PaperlessCustomFieldDataType.float =>
        const TextInputType.numberWithOptions(decimal: true),
      PaperlessCustomFieldDataType.documentLink => TextInputType.number,
      PaperlessCustomFieldDataType.longText => TextInputType.multiline,
      _ => TextInputType.text,
    };
  }

  void _setCustomFieldValue(int fieldId, Object? value) {
    setState(() {
      _selectedCustomFieldValues[fieldId] = value;
      _customFieldErrors = Map<int, String>.from(_customFieldErrors)
        ..remove(fieldId);
    });
  }

  void _removeCustomField(int fieldId) {
    setState(() {
      _selectedCustomFieldValues.remove(fieldId);
      _customFieldErrors = Map<int, String>.from(_customFieldErrors)
        ..remove(fieldId);
    });
    _customFieldControllers.remove(fieldId)?.dispose();
    _customFieldCurrencyControllers.remove(fieldId)?.dispose();
    _customFieldAmountControllers.remove(fieldId)?.dispose();
  }

  Future<void> _openCustomFieldSelection(
    List<PaperlessCustomField> definitions,
  ) async {
    final selectedIds = _selectedCustomFieldValues.keys.toSet();
    final available =
        definitions
            .where((item) => !selectedIds.contains(item.id))
            .toList(growable: false)
          ..sort((left, right) => left.name.compareTo(right.name));

    if (available.isEmpty) {
      _showStatusMessage(context.l10n.allCustomFieldsAlreadyAdded);
      return;
    }

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) =>
          _CustomFieldSelectionSheet(availableFields: available),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedCustomFieldValues[result] = null;
      _customFieldErrors = Map<int, String>.from(_customFieldErrors)
        ..remove(result);
    });
  }

  Future<void> _openCustomSelectOption(PaperlessCustomField field) async {
    final selectedValue = _selectedCustomFieldValues[field.id]?.toString();
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _CustomFieldValueSelectionSheet(
        fieldName: field.name,
        options: field.selectOptions,
        selectedValue: selectedValue,
      ),
    );

    if (!mounted) {
      return;
    }

    _setCustomFieldValue(field.id, result);
  }

  List<PaperlessDocumentCustomField>? _buildValidatedCustomFieldPayload(
    List<PaperlessCustomField> definitions,
  ) {
    final definitionsById = <int, PaperlessCustomField>{
      for (final definition in definitions) definition.id: definition,
    };
    final nextErrors = <int, String>{};
    final payload = <PaperlessDocumentCustomField>[];

    final sortedIds = _selectedCustomFieldValues.keys.toList(growable: false)
      ..sort();
    for (final fieldId in sortedIds) {
      final definition = definitionsById[fieldId];
      final rawValue = _selectedCustomFieldValues[fieldId];
      final normalized = _normalizeCustomFieldValue(rawValue, definition);
      if (normalized.error != null) {
        nextErrors[fieldId] = normalized.error!;
        continue;
      }

      payload.add(
        PaperlessDocumentCustomField(field: fieldId, value: normalized.value),
      );
    }

    if (nextErrors.isNotEmpty) {
      setState(() {
        _customFieldErrors = nextErrors;
      });
      return null;
    }

    if (_customFieldErrors.isNotEmpty) {
      setState(() {
        _customFieldErrors = <int, String>{};
      });
    }

    return payload;
  }

  ({Object? value, String? error}) _normalizeCustomFieldValue(
    Object? rawValue,
    PaperlessCustomField? definition,
  ) {
    if (definition == null) {
      if (rawValue is String && rawValue.trim().isEmpty) {
        return (value: null, error: null);
      }
      return (value: rawValue, error: null);
    }

    final type = definition.dataType;
    switch (type) {
      case PaperlessCustomFieldDataType.boolean:
        if (rawValue is bool) {
          return (value: rawValue, error: null);
        }
        final text = rawValue?.toString().toLowerCase().trim();
        if (text == null || text.isEmpty) {
          return (value: null, error: null);
        }
        if (text == 'true' || text == 'yes' || text == '1') {
          return (value: true, error: null);
        }
        if (text == 'false' || text == 'no' || text == '0') {
          return (value: false, error: null);
        }
        return (value: null, error: context.l10n.customFieldBooleanError);
      case PaperlessCustomFieldDataType.integer:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: null, error: null);
        }
        final normalizedText = _normalizeLocalizedNumericInput(
          context,
          text,
          allowDecimal: false,
        );
        final parsed = int.tryParse(normalizedText);
        if (parsed == null) {
          return (value: null, error: context.l10n.customFieldIntegerError);
        }
        return (value: parsed, error: null);
      case PaperlessCustomFieldDataType.float:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: null, error: null);
        }
        final normalizedText = _normalizeLocalizedNumericInput(context, text);
        final parsed = double.tryParse(normalizedText);
        if (parsed == null) {
          return (value: null, error: context.l10n.customFieldFloatError);
        }
        return (value: parsed, error: null);
      case PaperlessCustomFieldDataType.date:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: null, error: null);
        }
        if (DateTime.tryParse(text) == null) {
          return (value: null, error: context.l10n.customFieldDateError);
        }
        return (value: text, error: null);
      case PaperlessCustomFieldDataType.url:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: null, error: null);
        }
        final parsed = Uri.tryParse(text);
        if (parsed == null || !parsed.hasScheme) {
          return (value: null, error: context.l10n.customFieldUrlError);
        }
        return (value: text, error: null);
      case PaperlessCustomFieldDataType.documentLink:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: <int>[], error: null);
        }
        final parts = text
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
        final ids = <int>[];
        for (final part in parts) {
          final id = int.tryParse(part);
          if (id == null) {
            return (
              value: null,
              error: context.l10n.customFieldDocumentLinkError,
            );
          }
          ids.add(id);
        }
        return (value: ids, error: null);
      case PaperlessCustomFieldDataType.select:
        final text = rawValue?.toString().trim() ?? '';
        if (text.isEmpty) {
          return (value: null, error: null);
        }
        final exists = definition.selectOptions
            .where((option) => option.id == text)
            .isNotEmpty;
        if (!exists) {
          return (value: null, error: context.l10n.customFieldSelectError);
        }
        return (value: text, error: null);
      case PaperlessCustomFieldDataType.monetary:
        final monetaryValue = switch (rawValue) {
          _MonetaryCustomFieldValue value => value,
          _ => _parseMonetaryCustomFieldValue(
            rawValue,
            definition.defaultCurrency,
          ),
        };
        final currency = monetaryValue.currency.trim().toUpperCase();
        final amount = monetaryValue.amount.trim();
        if (currency.isEmpty && amount.isEmpty) {
          return (value: null, error: null);
        }
        if (amount.isEmpty) {
          return (value: null, error: context.l10n.customFieldAmountError);
        }
        final normalizedAmount = _normalizeLocalizedNumericInput(
          context,
          amount,
        );
        if (double.tryParse(normalizedAmount) == null) {
          return (value: null, error: context.l10n.customFieldMonetaryError);
        }
        final effectiveCurrency = currency.isNotEmpty
            ? currency
            : (definition.defaultCurrency ?? '').trim().toUpperCase();
        if (effectiveCurrency.isEmpty) {
          return (value: null, error: context.l10n.customFieldCurrencyError);
        }
        return (value: '$effectiveCurrency$normalizedAmount', error: null);
      case PaperlessCustomFieldDataType.string:
      case PaperlessCustomFieldDataType.longText:
      case PaperlessCustomFieldDataType.unknown:
        final text = rawValue?.toString() ?? '';
        if (text.trim().isEmpty) {
          return (value: null, error: null);
        }
        return (value: text.trim(), error: null);
    }
  }

  Future<void> _pickCreatedDate() async {
    final initialDate =
        DateTime.tryParse(_createdController.text.trim()) ??
        DateTime.tryParse(widget.document.created ?? '') ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _createdController.text = _formatDate(picked);
    });
  }

  void _removeSelectedTag(int tagId) {
    setState(() {
      _selectedTagIds = <int>{..._selectedTagIds}..remove(tagId);
    });
  }

  Future<void> _openTagSelection(List<PaperlessFilterOption> tags) async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _TagSelectionSheet(
        tags: tags,
        initialSelection: _selectedTagIds,
        onCreateTag: _createTag,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedTagIds = result;
    });
  }

  Future<void> _openCorrespondentSelection(
    List<PaperlessFilterOption> correspondents,
  ) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _SingleOptionSelectionSheet(
        title: dialogContext.l10n.selectCorrespondentDialogTitle,
        searchHint: dialogContext.l10n.searchCorrespondentsHint,
        emptyOptionLabel: dialogContext.l10n.noCorrespondentOption,
        noResultsMessage: dialogContext.l10n.noCorrespondentsMatchSearch,
        options: correspondents,
        selectedId: _selectedCorrespondentId,
        createActionLabel: dialogContext.l10n.newCorrespondentAction,
        onCreateOption: _createCorrespondentOption,
      ),
    );

    if (!mounted || result == _selectedCorrespondentId) {
      return;
    }

    setState(() {
      _selectedCorrespondentId = result;
    });
  }

  Future<void> _openDocumentTypeSelection(
    List<PaperlessFilterOption> documentTypes,
  ) async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _SingleOptionSelectionSheet(
        title: dialogContext.l10n.selectDocumentTypeDialogTitle,
        searchHint: dialogContext.l10n.searchDocumentTypesHint,
        emptyOptionLabel: dialogContext.l10n.noDocumentTypeOption,
        noResultsMessage: dialogContext.l10n.noDocumentTypesMatchSearch,
        options: documentTypes,
        selectedId: _selectedDocumentTypeId,
        createActionLabel: dialogContext.l10n.newDocumentTypeAction,
        onCreateOption: _createDocumentTypeOption,
      ),
    );

    if (!mounted || result == _selectedDocumentTypeId) {
      return;
    }

    setState(() {
      _selectedDocumentTypeId = result;
    });
  }

  Future<void> _createCorrespondent() async {
    setState(() {
      _isCreatingCorrespondent = true;
    });

    try {
      final created = await _createCorrespondentOption();
      if (!mounted || created == null) {
        return;
      }

      setState(() {
        _selectedCorrespondentId = created.id;
      });
      _showStatusMessage(context.l10n.correspondentCreated);
    } catch (error) {
      _showStatusMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingCorrespondent = false;
        });
      }
    }
  }

  Future<void> _createDocumentType() async {
    setState(() {
      _isCreatingDocumentType = true;
    });

    try {
      final created = await _createDocumentTypeOption();
      if (!mounted || created == null) {
        return;
      }

      setState(() {
        _selectedDocumentTypeId = created.id;
      });
      _showStatusMessage(context.l10n.documentTypeCreated);
    } catch (error) {
      _showStatusMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingDocumentType = false;
        });
      }
    }
  }

  Future<PaperlessFilterOption?> _createCorrespondentOption() async {
    final name = await _promptForNewOption(
      title: context.l10n.newCorrespondentAction,
      fieldLabel: context.l10n.correspondentNameLabel,
    );
    if (name == null) {
      return null;
    }

    final created = await ref
        .read(documentsRepositoryProvider)
        .createCorrespondent(name: name);
    final _ = await ref.refresh(correspondentOptionsProvider.future);
    return created;
  }

  Future<PaperlessFilterOption?> _createDocumentTypeOption() async {
    final name = await _promptForNewOption(
      title: context.l10n.newDocumentTypeAction,
      fieldLabel: context.l10n.documentTypeNameLabel,
    );
    if (name == null) {
      return null;
    }

    final created = await ref
        .read(documentsRepositoryProvider)
        .createDocumentType(name: name);
    final _ = await ref.refresh(documentTypeOptionsProvider.future);
    return created;
  }

  Future<PaperlessFilterOption?> _createTag() async {
    final name = await _promptForNewOption(
      title: context.l10n.newTagAction,
      fieldLabel: context.l10n.tagNameLabel,
    );
    if (name == null) {
      return null;
    }

    if (!mounted) {
      return null;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.newTagAction),
        content: Text(dialogContext.l10n.createTagConfirmationMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.createAction),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return null;
    }

    final created = await ref
        .read(documentsRepositoryProvider)
        .createTag(name: name);
    final _ = await ref.refresh(tagOptionsProvider.future);
    return created;
  }

  Future<String?> _promptForNewOption({
    required String title,
    required String fieldLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _CreateOptionDialog(title: title, fieldLabel: fieldLabel),
    );
  }

  void _showStatusMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _updatePreviewState(_ScreenshotPreviewState state) {
    if (!mounted || _previewState == state) {
      return;
    }

    setState(() {
      _previewState = state;
    });
  }

  Future<void> _save() async {
    setState(() {
      _hasSubmitted = true;
    });

    if (!_isValid) {
      return;
    }

    List<PaperlessCustomField> customFieldDefinitions;
    try {
      customFieldDefinitions = await ref.read(
        customFieldDefinitionsProvider.future,
      );
    } catch (_) {
      customFieldDefinitions = const <PaperlessCustomField>[];
    }

    final customFieldPayload = _buildValidatedCustomFieldPayload(
      customFieldDefinitions,
    );
    if (customFieldPayload == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedDocument = await ref
          .read(documentsRepositoryProvider)
          .updateDocumentMetadata(
            documentId: widget.document.id,
            title: _titleController.text.trim(),
            created: _createdController.text.trim(),
            correspondentId: _selectedCorrespondentId,
            documentTypeId: _selectedDocumentTypeId,
            tagIds: _selectedTagIds.toList(growable: false),
            customFields: customFieldPayload,
          );

      ref.invalidate(documentDetailProvider(widget.document.id));
      ref.invalidate(documentsPageProvider);
      ref.invalidate(recentUploadsProvider);
      ref.invalidate(reviewDocumentsProvider);
      ref
          .read(recentlyOpenedDocumentsProvider.notifier)
          .refreshDocument(updatedDocument);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedDocument);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _initialCreatedValue(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) {
      return value?.trim() ?? '';
    }

    return _formatDate(parsed);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _EditMetadataHero extends StatefulWidget {
  const _EditMetadataHero({
    required this.document,
    required this.repository,
    required this.selectedPage,
    required this.onPreviewStateChanged,
    required this.onSelectPage,
    required this.badges,
  });

  final PaperlessDocument document;
  final DocumentsRepository repository;
  final int selectedPage;
  final ValueChanged<_ScreenshotPreviewState> onPreviewStateChanged;
  final ValueChanged<int> onSelectPage;
  final List<String> badges;

  @override
  State<_EditMetadataHero> createState() => _EditMetadataHeroState();
}

class _EditMetadataHeroState extends State<_EditMetadataHero> {
  _ScreenshotPreviewState? _lastReportedPreviewState;
  late Map<String, String> _headers;
  late PdfDocumentRefUri _previewDocumentRef;

  @override
  void initState() {
    super.initState();
    _refreshPreviewSource();
  }

  @override
  void didUpdateWidget(covariant _EditMetadataHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.repository != widget.repository) {
      _refreshPreviewSource();
      _lastReportedPreviewState = null;
    }
  }

  void _refreshPreviewSource() {
    final previewUri = widget.repository.buildDocumentPreviewUri(
      documentId: widget.document.id,
    );
    _headers = Map<String, String>.unmodifiable(
      widget.repository.buildAuthenticatedHeaders(),
    );
    _previewDocumentRef = PdfDocumentRefUri(
      previewUri,
      headers: _headers,
      key: PdfDocumentRefKey(previewUri.toString(), [
        _headers['Authorization'],
      ]),
    );
  }

  void _schedulePreviewState(_ScreenshotPreviewState state) {
    if (_lastReportedPreviewState == state) {
      return;
    }

    _lastReportedPreviewState = state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      widget.onPreviewStateChanged(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PdfDocumentViewBuilder(
          documentRef: _previewDocumentRef,
          builder: (context, pdfDocument) {
            final effectivePageCount = pdfDocument?.pages.length ?? 0;
            final effectiveSelectedPage = effectivePageCount > 0
                ? widget.selectedPage.clamp(1, effectivePageCount)
                : 1;

            _schedulePreviewState(_ScreenshotPreviewState.ready);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 0.74,
                      child: pdfDocument == null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                _DocumentThumbnailImage(
                                  imageUri: widget.repository
                                      .buildDocumentThumbnailUri(
                                        widget.document.id,
                                      ),
                                  headers: _headers,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                  ),
                                ),
                              ],
                            )
                          : ColoredBox(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: PdfPageView(
                                  key: ValueKey<int>(effectiveSelectedPage),
                                  document: pdfDocument,
                                  pageNumber: effectiveSelectedPage,
                                  alignment: Alignment.topCenter,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (effectivePageCount > 1) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: effectiveSelectedPage > 1
                            ? () =>
                                  widget.onSelectPage(effectiveSelectedPage - 1)
                            : null,
                        tooltip: l10n.previousAction,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              l10n.scannedPageLabel(effectiveSelectedPage),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.documentPages(effectivePageCount),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: effectiveSelectedPage < effectivePageCount
                            ? () =>
                                  widget.onSelectPage(effectiveSelectedPage + 1)
                            : null,
                        tooltip: l10n.nextAction,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
          loadingBuilder: (context) {
            _schedulePreviewState(_ScreenshotPreviewState.loading);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const AspectRatio(
                  aspectRatio: 0.74,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            _schedulePreviewState(_ScreenshotPreviewState.ready);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 0.74,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _DocumentThumbnailImage(
                        imageUri: widget.repository.buildDocumentThumbnailUri(
                          widget.document.id,
                        ),
                        headers: _headers,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        if (widget.badges.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.badges
                .map((badge) => _EditMetaBadge(label: badge))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _EditFieldSection extends StatelessWidget {
  const _EditFieldSection({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _EditSectionCard extends StatelessWidget {
  const _EditSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _EditMetadataTextField extends StatelessWidget {
  const _EditMetadataTextField({
    required this.controller,
    required this.enabled,
    this.hintText,
    this.textInputAction,
    this.keyboardType,
    this.errorText,
    this.suffix,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? hintText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final String? errorText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primaryContainer,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.8),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _EditSelectionField extends StatelessWidget {
  const _EditSelectionField({
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.actionIcon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String? value;
  final String placeholder;
  final IconData actionIcon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value?.trim().isNotEmpty == true ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value?.trim().isNotEmpty == true
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
              const SizedBox(width: 10),
              Icon(
                actionIcon,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSquareActionButton extends StatelessWidget {
  const _EditSquareActionButton({
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(icon, color: theme.colorScheme.onSurface, size: 24),
          ),
        ),
      ),
    );
  }
}

class _EditSelectionChip extends StatelessWidget {
  const _EditSelectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    this.onPressed,
    this.onDeleted,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
        : theme.colorScheme.surfaceContainerHigh;
    final foregroundColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return InputChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: foregroundColor),
      selected: selected,
      onPressed: enabled ? onPressed : null,
      onDeleted: enabled ? onDeleted : null,
      deleteIcon: Icon(Icons.close_rounded, size: 16, color: foregroundColor),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _EditMetaBadge extends StatelessWidget {
  const _EditMetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _EditInlineStatusCard extends StatelessWidget {
  const _EditInlineStatusCard({
    required this.message,
    required this.isError,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError
        ? theme.colorScheme.error.withValues(alpha: 0.14)
        : theme.colorScheme.surfaceContainerLow;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditLoadingCard extends StatelessWidget {
  const _EditLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: LinearProgressIndicator(),
      ),
    );
  }
}

String? _formatMetadataTimestamp(BuildContext context, String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return trimmed;
  }

  return formatAbsoluteDate(parsed, localeName: context.localeName);
}

class _DocumentSummaryCard extends StatelessWidget {
  const _DocumentSummaryCard({
    required this.primaryLabel,
    required this.badges,
    this.trailingLabel,
  });

  final String primaryLabel;
  final List<String> badges;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  primaryLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailingLabel != null &&
                    trailingLabel!.trim().isNotEmpty) ...[
                  Text(
                    trailingLabel!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges
                    .map((badge) => _StatBadge(label: badge))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetadataInfoRow extends StatelessWidget {
  const _MetadataInfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Text(
              value?.trim().isNotEmpty == true ? value! : '-',
              textAlign: TextAlign.left,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataTagsRow extends StatelessWidget {
  const _MetadataTagsRow({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Text(
              '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values
                  .map(
                    (value) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          value,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.title,
    required this.document,
    required this.pageCount,
    required this.selectedPage,
    required this.preferFallbackWhileLoading,
    required this.pageStripScrollController,
    required this.thumbnailWidget,
    required this.thumbnailImageProvider,
    required this.repository,
    required this.onPreviewStateChanged,
    required this.onSelectPage,
    required this.onPreview,
  });

  final String title;
  final PaperlessDocument document;
  final int pageCount;
  final int selectedPage;
  final bool preferFallbackWhileLoading;
  final ScrollController pageStripScrollController;
  final Widget? thumbnailWidget;
  final ImageProvider<Object>? thumbnailImageProvider;
  final DocumentsRepository repository;
  final ValueChanged<_ScreenshotPreviewState> onPreviewStateChanged;
  final ValueChanged<int> onSelectPage;
  final VoidCallback? onPreview;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  _ScreenshotPreviewState? _lastReportedPreviewState;
  late PdfDocumentRefUri _previewDocumentRef;
  late Map<String, String> _headers;

  @override
  void initState() {
    super.initState();
    _refreshPreviewSource();
  }

  @override
  void didUpdateWidget(covariant _PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.repository != widget.repository) {
      _refreshPreviewSource();
    }

    if (oldWidget.document.id != widget.document.id ||
        oldWidget.preferFallbackWhileLoading !=
            widget.preferFallbackWhileLoading) {
      _lastReportedPreviewState = null;
    }
  }

  void _refreshPreviewSource() {
    final previewUri = widget.repository.buildDocumentPreviewUri(
      documentId: widget.document.id,
    );
    _headers = Map<String, String>.unmodifiable(
      widget.repository.buildAuthenticatedHeaders(),
    );
    _previewDocumentRef = PdfDocumentRefUri(
      previewUri,
      headers: _headers,
      key: PdfDocumentRefKey(previewUri.toString(), [
        _headers['Authorization'],
      ]),
    );
  }

  void _schedulePreviewState(_ScreenshotPreviewState state) {
    if (_lastReportedPreviewState == state) {
      return;
    }

    _lastReportedPreviewState = state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      widget.onPreviewStateChanged(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            PdfDocumentViewBuilder(
              documentRef: _previewDocumentRef,
              builder: (context, pdfDocument) {
                if (pdfDocument == null) {
                  _schedulePreviewState(_ScreenshotPreviewState.ready);
                  return _PreviewFallback(
                    document: widget.document,
                    thumbnailWidget: widget.thumbnailWidget,
                    thumbnailImageProvider: widget.thumbnailImageProvider,
                    repository: widget.repository,
                    onPreview: widget.onPreview,
                    aspectRatio: 0.84,
                  );
                }

                final effectivePageCount = pdfDocument.pages.length;
                final effectiveSelectedPage = widget.selectedPage.clamp(
                  1,
                  effectivePageCount,
                );

                _schedulePreviewState(_ScreenshotPreviewState.ready);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewPanel(
                      pdfDocument: pdfDocument,
                      selectedPage: effectiveSelectedPage,
                      onPreview: widget.onPreview,
                      aspectRatio: 0.84,
                    ),
                    const SizedBox(height: 12),
                    _PagePreviewStrip(
                      pageCount: effectivePageCount,
                      selectedPage: effectiveSelectedPage,
                      pdfDocument: pdfDocument,
                      scrollController: widget.pageStripScrollController,
                      onPageSelected: widget.onSelectPage,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Page $effectiveSelectedPage of $effectivePageCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loadingBuilder: (context) {
                if (widget.preferFallbackWhileLoading) {
                  _schedulePreviewState(_ScreenshotPreviewState.ready);
                  return _PreviewFallback(
                    document: widget.document,
                    thumbnailWidget: widget.thumbnailWidget,
                    thumbnailImageProvider: widget.thumbnailImageProvider,
                    repository: widget.repository,
                    onPreview: widget.onPreview,
                    aspectRatio: 0.84,
                  );
                }

                _schedulePreviewState(_ScreenshotPreviewState.loading);
                return _PreviewLoadingState(
                  onPreview: widget.onPreview,
                  aspectRatio: 0.84,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                _schedulePreviewState(_ScreenshotPreviewState.ready);
                return _PreviewFallback(
                  document: widget.document,
                  thumbnailWidget: widget.thumbnailWidget,
                  thumbnailImageProvider: widget.thumbnailImageProvider,
                  repository: widget.repository,
                  onPreview: widget.onPreview,
                  aspectRatio: 0.84,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedOptionRow extends StatelessWidget {
  const _ResolvedOptionRow({
    required this.label,
    required this.optionId,
    required this.options,
    this.fallbackValue,
  });

  final String label;
  final int? optionId;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final String? fallbackValue;

  @override
  Widget build(BuildContext context) {
    if (optionId == null) {
      return const SizedBox.shrink();
    }

    return options.when(
      data: (items) {
        final match = items.where((item) => item.id == optionId).firstOrNull;
        return _MetadataInfoRow(
          label: label,
          value: match?.name ?? fallbackValue ?? optionId.toString(),
        );
      },
      error: (error, stackTrace) => _MetadataInfoRow(
        label: label,
        value: fallbackValue ?? optionId.toString(),
      ),
      loading: () =>
          _MetadataInfoRow(label: label, value: context.l10n.loadingStatus),
    );
  }
}

class _CreateOptionDialog extends StatefulWidget {
  const _CreateOptionDialog({required this.title, required this.fieldLabel});

  final String title;
  final String fieldLabel;

  @override
  State<_CreateOptionDialog> createState() => _CreateOptionDialogState();
}

class _CreateOptionDialogState extends State<_CreateOptionDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = context.l10n.enterNameValidation;
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.createAction),
        ),
      ],
    );
  }
}

class _TagSelectionSheet extends StatefulWidget {
  const _TagSelectionSheet({
    required this.tags,
    required this.initialSelection,
    required this.onCreateTag,
  });

  final List<PaperlessFilterOption> tags;
  final Set<int> initialSelection;
  final Future<PaperlessFilterOption?> Function() onCreateTag;

  @override
  State<_TagSelectionSheet> createState() => _TagSelectionSheetState();
}

class _SingleOptionSelectionSheet extends StatefulWidget {
  const _SingleOptionSelectionSheet({
    required this.title,
    required this.searchHint,
    required this.emptyOptionLabel,
    required this.noResultsMessage,
    required this.options,
    required this.selectedId,
    required this.createActionLabel,
    required this.onCreateOption,
  });

  final String title;
  final String searchHint;
  final String emptyOptionLabel;
  final String noResultsMessage;
  final List<PaperlessFilterOption> options;
  final int? selectedId;
  final String createActionLabel;
  final Future<PaperlessFilterOption?> Function() onCreateOption;

  @override
  State<_SingleOptionSelectionSheet> createState() =>
      _SingleOptionSelectionSheetState();
}

class _SingleOptionSelectionSheetState
    extends State<_SingleOptionSelectionSheet> {
  late final TextEditingController _searchController;
  late List<PaperlessFilterOption> _options;
  String _query = '';
  bool _isCreatingOption = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _options = List<PaperlessFilterOption>.of(widget.options);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<PaperlessFilterOption> get _visibleOptions {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _options.where((option) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      return option.name.toLowerCase().contains(normalizedQuery);
    }).toList();

    filtered.sort((left, right) {
      final leftSelected = left.id == widget.selectedId;
      final rightSelected = right.id == widget.selectedId;
      if (leftSelected != rightSelected) {
        return leftSelected ? -1 : 1;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return filtered;
  }

  void _handleSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
  }

  Future<void> _createOption() async {
    setState(() {
      _isCreatingOption = true;
    });

    try {
      final created = await widget.onCreateOption();
      if (!mounted || created == null) {
        return;
      }

      Navigator.of(context).pop<int?>(created.id);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOption = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleOptions = _visibleOptions;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isCreatingOption ? null : _createOption,
                    icon: _isCreatingOption
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      _isCreatingOption
                          ? context.l10n.addingAction
                          : widget.createActionLabel,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close),
                            tooltip: context.l10n.clearSearchTooltip,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: widget.selectedId == null
                      ? theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.45,
                        )
                      : null,
                  leading: Icon(
                    widget.selectedId == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: widget.selectedId == null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(widget.emptyOptionLabel),
                  onTap: () => Navigator.of(context).pop<int?>(null),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: visibleOptions.isEmpty
                      ? Center(
                          child: Text(
                            widget.noResultsMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: visibleOptions.length,
                          itemBuilder: (context, index) {
                            final option = visibleOptions[index];
                            final isSelected = option.id == widget.selectedId;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tileColor: isSelected
                                  ? theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.45)
                                  : null,
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(option.name),
                              onTap: () =>
                                  Navigator.of(context).pop<int?>(option.id),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(widget.selectedId),
                    child: Text(context.l10n.cancelAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomFieldSelectionSheet extends StatefulWidget {
  const _CustomFieldSelectionSheet({required this.availableFields});

  final List<PaperlessCustomField> availableFields;

  @override
  State<_CustomFieldSelectionSheet> createState() =>
      _CustomFieldSelectionSheetState();
}

class _CustomFieldSelectionSheetState
    extends State<_CustomFieldSelectionSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {
          _query = _searchController.text;
        });
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleFields =
        widget.availableFields
            .where((field) {
              if (normalizedQuery.isEmpty) {
                return true;
              }

              return field.name.toLowerCase().contains(normalizedQuery);
            })
            .toList(growable: false)
          ..sort((left, right) => left.name.compareTo(right.name));

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addCustomFieldTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchCustomFieldsHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visibleFields.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noCustomFieldsMatchSearch,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visibleFields.length,
                        itemBuilder: (context, index) {
                          final field = visibleFields[index];
                          return ListTile(
                            title: Text(field.name),
                            subtitle: Text(
                              _customFieldTypeLabel(l10n, field.dataType),
                            ),
                            onTap: () => Navigator.of(context).pop(field.id),
                          );
                        },
                      ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancelAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomFieldValueSelectionSheet extends StatelessWidget {
  const _CustomFieldValueSelectionSheet({
    required this.fieldName,
    required this.options,
    required this.selectedValue,
  });

  final String fieldName;
  final List<PaperlessCustomFieldSelectOption> options;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  selectedValue == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(l10n.customFieldNoValueOption),
                onTap: () => Navigator.of(context).pop<String?>(null),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = option.id == selectedValue;
                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(option.label),
                      onTap: () =>
                          Navigator.of(context).pop<String?>(option.id),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedValue),
                  child: Text(context.l10n.cancelAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagSelectionSheetState extends State<_TagSelectionSheet> {
  late final TextEditingController _searchController;
  late List<PaperlessFilterOption> _tags;
  late Set<int> _selection;
  String _query = '';
  bool _isCreatingTag = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tags = List<PaperlessFilterOption>.of(widget.tags);
    _selection = <int>{...widget.initialSelection};
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<PaperlessFilterOption> get _selectedTags {
    final selected = _tags.where((tag) => _selection.contains(tag.id)).toList();
    selected.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return selected;
  }

  List<PaperlessFilterOption> get _visibleTags {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _tags.where((tag) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      return tag.name.toLowerCase().contains(normalizedQuery);
    }).toList();

    filtered.sort((left, right) {
      final leftSelected = _selection.contains(left.id);
      final rightSelected = _selection.contains(right.id);
      if (leftSelected != rightSelected) {
        return leftSelected ? -1 : 1;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return filtered;
  }

  void _handleSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
  }

  void _toggleTag(int tagId, bool selected) {
    setState(() {
      final nextSelection = <int>{..._selection};
      if (selected) {
        nextSelection.add(tagId);
      } else {
        nextSelection.remove(tagId);
      }
      _selection = nextSelection;
    });
  }

  void _clearSelection() {
    setState(() {
      _selection = <int>{};
    });
  }

  Future<void> _createTag() async {
    setState(() {
      _isCreatingTag = true;
    });

    try {
      final created = await widget.onCreateTag();
      if (!mounted || created == null) {
        return;
      }

      setState(() {
        final nextTags = <PaperlessFilterOption>[
          for (final tag in _tags)
            if (tag.id != created.id) tag,
          created,
        ];
        nextTags.sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
        _tags = nextTags;
        _selection = <int>{..._selection, created.id};
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.tagCreated)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTag = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selectedTags = _selectedTags;
    final visibleTags = _visibleTags;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectTagsDialogTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _isCreatingTag ? null : _createTag,
                    icon: _isCreatingTag
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(
                      _isCreatingTag ? l10n.addingAction : l10n.newTagAction,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchTagsHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close),
                            tooltip: l10n.clearSearchTooltip,
                          ),
                  ),
                ),
                if (selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.selectedTagsSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in selectedTags)
                        InputChip(
                          label: Text(tag.name),
                          onDeleted: () => _toggleTag(tag.id, false),
                          deleteIcon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.availableTagsSectionTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_selection.isNotEmpty)
                      TextButton(
                        onPressed: _clearSelection,
                        child: Text(l10n.clearAction),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _tags.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noTagsAvailableOnServer,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : visibleTags.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noTagsMatchSearch,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: visibleTags.length,
                          itemBuilder: (context, index) {
                            final tag = visibleTags[index];
                            final isSelected = _selection.contains(tag.id);

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(tag.name),
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tileColor: isSelected
                                  ? theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.45)
                                  : null,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              onChanged: (checked) =>
                                  _toggleTag(tag.id, checked == true),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selection),
                      child: Text(l10n.applyAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedTagsRow extends StatelessWidget {
  const _ResolvedTagsRow({required this.document, required this.options});

  final PaperlessDocument document;
  final AsyncValue<List<PaperlessFilterOption>> options;

  @override
  Widget build(BuildContext context) {
    if (document.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return options.when(
      data: (items) {
        final names = document.tags
            .map(
              (tagId) =>
                  items.where((item) => item.id == tagId).firstOrNull?.name ??
                  '#$tagId',
            )
            .toList();
        return _MetadataTagsRow(label: context.l10n.tagsLabel, values: names);
      },
      error: (error, stackTrace) => _MetadataTagsRow(
        label: context.l10n.tagsLabel,
        values: document.tags.map((tagId) => tagId.toString()).toList(),
      ),
      loading: () => _MetadataTagsRow(
        label: context.l10n.tagsLabel,
        values: [context.l10n.loadingStatus],
      ),
    );
  }
}

class _ResolvedCustomFieldsRows extends StatelessWidget {
  const _ResolvedCustomFieldsRows({
    required this.document,
    required this.definitions,
  });

  final PaperlessDocument document;
  final AsyncValue<List<PaperlessCustomField>> definitions;

  @override
  Widget build(BuildContext context) {
    if (document.customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return definitions.when(
      data: (items) {
        final namesById = <int, PaperlessCustomField>{
          for (final field in items) field.id: field,
        };

        return Column(
          children: [
            for (final instance in document.customFields)
              _MetadataInfoRow(
                label:
                    namesById[instance.field]?.name ??
                    context.l10n.customFieldFallbackLabel(instance.field),
                value: _formatCustomFieldValue(
                  context,
                  instance.value,
                  namesById[instance.field],
                ),
              ),
          ],
        );
      },
      error: (error, stackTrace) => Column(
        children: [
          for (final instance in document.customFields)
            _MetadataInfoRow(
              label: context.l10n.customFieldFallbackLabel(instance.field),
              value: _formatCustomFieldValue(context, instance.value, null),
            ),
        ],
      ),
      loading: () => _MetadataInfoRow(
        label: context.l10n.customFieldsLabel,
        value: context.l10n.loadingStatus,
      ),
    );
  }
}

String _formatCustomFieldValue(
  BuildContext context,
  Object? value,
  PaperlessCustomField? field,
) {
  if (value == null) {
    return '';
  }

  if (field?.dataType == PaperlessCustomFieldDataType.select) {
    final optionId = value.toString();
    final option = field?.selectOptions
        .where((item) => item.id == optionId)
        .firstOrNull;
    return option?.label ?? optionId;
  }

  if (field?.dataType == PaperlessCustomFieldDataType.boolean) {
    if (value is bool) {
      return value
          ? context.l10n.customFieldBooleanTrue
          : context.l10n.customFieldBooleanFalse;
    }
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true') {
      return context.l10n.customFieldBooleanTrue;
    }
    if (normalized == 'false') {
      return context.l10n.customFieldBooleanFalse;
    }
  }

  if (field?.dataType == PaperlessCustomFieldDataType.monetary) {
    final parsed = _parseMonetaryCustomFieldValue(
      value,
      field?.defaultCurrency,
    );
    final formattedAmount = _formatLocalizedNumericString(
      context,
      parsed.amount,
    );
    if (parsed.amount.trim().isEmpty && parsed.currency.trim().isEmpty) {
      return '';
    }
    if (parsed.currency.trim().isEmpty) {
      return formattedAmount;
    }
    if (formattedAmount.isEmpty) {
      return parsed.currency.trim();
    }
    return '${parsed.currency.trim()} $formattedAmount';
  }

  if (field?.dataType == PaperlessCustomFieldDataType.integer ||
      field?.dataType == PaperlessCustomFieldDataType.float) {
    return _formatLocalizedNumericString(context, value.toString());
  }

  if (value is List) {
    return value.map((item) => item.toString()).join(', ');
  }

  return value.toString();
}

String _customFieldTypeLabel(
  AppLocalizations l10n,
  PaperlessCustomFieldDataType type,
) {
  return switch (type) {
    PaperlessCustomFieldDataType.string => l10n.customFieldTypeString,
    PaperlessCustomFieldDataType.url => l10n.customFieldTypeUrl,
    PaperlessCustomFieldDataType.date => l10n.customFieldTypeDate,
    PaperlessCustomFieldDataType.boolean => l10n.customFieldTypeBoolean,
    PaperlessCustomFieldDataType.integer => l10n.customFieldTypeInteger,
    PaperlessCustomFieldDataType.float => l10n.customFieldTypeFloat,
    PaperlessCustomFieldDataType.monetary => l10n.customFieldTypeMonetary,
    PaperlessCustomFieldDataType.documentLink =>
      l10n.customFieldTypeDocumentLink,
    PaperlessCustomFieldDataType.select => l10n.customFieldTypeSelect,
    PaperlessCustomFieldDataType.longText => l10n.customFieldTypeLongText,
    PaperlessCustomFieldDataType.unknown => l10n.unknownLabel,
  };
}

_MonetaryCustomFieldValue _parseMonetaryCustomFieldValue(
  Object? value,
  String? defaultCurrency,
) {
  if (value is _MonetaryCustomFieldValue) {
    return value;
  }

  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return _MonetaryCustomFieldValue(
      currency: defaultCurrency ?? '',
      amount: '',
    );
  }

  final prefixedMoneyMatch = RegExp(
    r'^([A-Za-z]{3})\s*([-+]?\d+(?:[\.,]\d+)?)$',
  ).firstMatch(raw);
  if (prefixedMoneyMatch != null) {
    return _MonetaryCustomFieldValue(
      currency: prefixedMoneyMatch.group(1)!.toUpperCase(),
      amount: prefixedMoneyMatch.group(2)!,
    );
  }

  return _MonetaryCustomFieldValue(
    currency: defaultCurrency ?? '',
    amount: raw,
  );
}

class _MonetaryCustomFieldValue {
  const _MonetaryCustomFieldValue({
    required this.currency,
    required this.amount,
  });

  final String currency;
  final String amount;
}

String _formatLocalizedNumericString(BuildContext context, String rawValue) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = trimmed.replaceAll(',', '.');
  final parsed = double.tryParse(normalized);
  if (parsed == null) {
    return trimmed;
  }

  final decimalSeparatorIndex = normalized.indexOf('.');
  final fractionDigits = decimalSeparatorIndex == -1
      ? 0
      : normalized.length - decimalSeparatorIndex - 1;

  final formatter = NumberFormat.decimalPattern(context.localeName)
    ..minimumFractionDigits = fractionDigits
    ..maximumFractionDigits = fractionDigits;

  return formatter.format(parsed);
}

String _normalizeLocalizedNumericInput(
  BuildContext context,
  String rawValue, {
  bool allowDecimal = true,
}) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final symbols = NumberFormat.decimalPattern(context.localeName).symbols;
  final decimalSeparator = symbols.DECIMAL_SEP;
  final groupSeparator = symbols.GROUP_SEP;
  final compact = trimmed.replaceAll('\u00a0', '').replaceAll(' ', '');

  if (!allowDecimal) {
    return compact
        .replaceAll(groupSeparator, '')
        .replaceAll(RegExp(r'[\.,]'), '');
  }

  if (compact.contains(',') && compact.contains('.')) {
    final lastComma = compact.lastIndexOf(',');
    final lastDot = compact.lastIndexOf('.');
    final decimal = lastComma > lastDot ? ',' : '.';
    final group = decimal == ',' ? '.' : ',';
    return compact.replaceAll(group, '').replaceAll(decimal, '.');
  }

  if (compact.contains(decimalSeparator)) {
    return compact
        .replaceAll(groupSeparator, '')
        .replaceAll(decimalSeparator, '.');
  }

  if (compact.contains(',') || compact.contains('.')) {
    final separator = compact.contains(',') ? ',' : '.';
    final separatorIndex = compact.lastIndexOf(separator);
    final fractionLength = compact.length - separatorIndex - 1;
    final looksLikeGrouping =
        separator == groupSeparator && fractionLength == 3;
    if (looksLikeGrouping) {
      return compact.replaceAll(separator, '');
    }
    return compact.replaceAll(separator, '.');
  }

  return compact;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.pdfDocument,
    required this.selectedPage,
    required this.onPreview,
    this.aspectRatio = 16 / 11,
  });

  final PdfDocument pdfDocument;
  final int selectedPage;
  final VoidCallback? onPreview;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return _ScreenshotPreviewStateMarker(
      state: _ScreenshotPreviewState.ready,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: PdfPageView(
                    key: ValueKey<int>(selectedPage),
                    document: pdfDocument,
                    pageNumber: selectedPage,
                    alignment: Alignment.topCenter,
                    decoration: const BoxDecoration(color: Colors.white),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onPreview,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(context.l10n.openAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagePreviewStrip extends StatelessWidget {
  const _PagePreviewStrip({
    required this.pageCount,
    required this.selectedPage,
    required this.pdfDocument,
    required this.scrollController,
    required this.onPageSelected,
  });

  final int pageCount;
  final int selectedPage;
  final PdfDocument pdfDocument;
  final ScrollController scrollController;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: pageCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _PagePreviewTile(
            pageNumber: index + 1,
            selected: selectedPage == index + 1,
            pdfDocument: pdfDocument,
            onTap: () => onPageSelected(index + 1),
          );
        },
      ),
    );
  }
}

class _PagePreviewTile extends StatelessWidget {
  const _PagePreviewTile({
    required this.pageNumber,
    required this.selected,
    required this.pdfDocument,
    required this.onTap,
  });

  final int pageNumber;
  final bool selected;
  final PdfDocument pdfDocument;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 98,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.outlineVariant,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: PdfPageView(
                          key: ValueKey<int>(pageNumber),
                          document: pdfDocument,
                          pageNumber: pageNumber,
                          alignment: Alignment.topCenter,
                          decoration: const BoxDecoration(color: Colors.white),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.l10n.scannedPageLabel(pageNumber),
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  const _PreviewLoadingState({
    required this.onPreview,
    required this.aspectRatio,
  });

  final VoidCallback? onPreview;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return _ScreenshotPreviewStateMarker(
      state: _ScreenshotPreviewState.loading,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: const ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onPreview,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(context.l10n.openAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({
    required this.document,
    required this.thumbnailWidget,
    required this.thumbnailImageProvider,
    required this.repository,
    required this.onPreview,
    required this.aspectRatio,
  });

  final PaperlessDocument document;
  final Widget? thumbnailWidget;
  final ImageProvider<Object>? thumbnailImageProvider;
  final DocumentsRepository repository;
  final VoidCallback? onPreview;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageCount = document.pageCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThumbnailFallbackPanel(
          document: document,
          thumbnailWidget: thumbnailWidget,
          thumbnailImageProvider: thumbnailImageProvider,
          repository: repository,
          onPreview: onPreview,
          aspectRatio: aspectRatio,
        ),
        if (pageCount > 0) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              '$pageCount page${pageCount == 1 ? '' : 's'}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThumbnailFallbackPanel extends StatelessWidget {
  const _ThumbnailFallbackPanel({
    required this.document,
    required this.thumbnailWidget,
    required this.thumbnailImageProvider,
    required this.repository,
    required this.onPreview,
    required this.aspectRatio,
  });

  final PaperlessDocument document;
  final Widget? thumbnailWidget;
  final ImageProvider<Object>? thumbnailImageProvider;
  final DocumentsRepository repository;
  final VoidCallback? onPreview;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return _ScreenshotPreviewStateMarker(
      state: _ScreenshotPreviewState.ready,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child:
                  thumbnailWidget ??
                  (thumbnailImageProvider != null
                      ? Image(image: thumbnailImageProvider!, fit: BoxFit.cover)
                      : _DocumentThumbnailImage(
                          imageUri: repository.buildDocumentThumbnailUri(
                            document.id,
                          ),
                          headers: repository.buildAuthenticatedHeaders(),
                        )),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onPreview,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(context.l10n.openAction),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScreenshotPreviewState { loading, ready }

class _ScreenshotPreviewStateMarker extends StatelessWidget {
  const _ScreenshotPreviewStateMarker({
    required this.state,
    required this.child,
  });

  final _ScreenshotPreviewState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        IgnorePointer(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(switch (state) {
                _ScreenshotPreviewState.loading =>
                  'paperless-screenshot-document-preview-loading',
                _ScreenshotPreviewState.ready =>
                  'paperless-screenshot-document-preview-ready',
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentFullscreenPreviewPage extends StatefulWidget {
  const _DocumentFullscreenPreviewPage({
    required this.document,
    required this.initialPage,
  });

  final PaperlessDocument document;
  final int initialPage;

  @override
  State<_DocumentFullscreenPreviewPage> createState() =>
      _DocumentFullscreenPreviewPageState();
}

class _DocumentFullscreenPreviewPageState
    extends State<_DocumentFullscreenPreviewPage> {
  int _currentPage = 1;
  late PdfDocumentRefUri _previewDocumentRef;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _refreshPreviewSource();
  }

  @override
  void didUpdateWidget(covariant _DocumentFullscreenPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      _refreshPreviewSource();
    }
  }

  void _refreshPreviewSource() {
    final repository = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(documentsRepositoryProvider);
    final previewUri = repository.buildDocumentPreviewUri(
      documentId: widget.document.id,
    );
    final headers = Map<String, String>.unmodifiable(
      repository.buildAuthenticatedHeaders(),
    );
    _previewDocumentRef = PdfDocumentRefUri(
      previewUri,
      headers: headers,
      key: PdfDocumentRefKey(previewUri.toString(), [headers['Authorization']]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.document.pageCount;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage.clamp(1, totalPages)} / $totalPages',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PdfViewer(
        _previewDocumentRef,
        initialPageNumber: widget.initialPage,
        params: PdfViewerParams(
          backgroundColor: Colors.black,
          pageDropShadow: null,
          margin: 12,
          onPageChanged: (pageNumber) {
            if (pageNumber == null || pageNumber == _currentPage || !mounted) {
              return;
            }

            setState(() {
              _currentPage = pageNumber;
            });
          },
        ),
      ),
    );
  }
}

class _DocumentThumbnailImage extends StatelessWidget {
  const _DocumentThumbnailImage({
    required this.imageUri,
    required this.headers,
  });

  final Uri imageUri;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Image.network(
      imageUri.toString(),
      headers: headers,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return ColoredBox(
          color: theme.colorScheme.surfaceContainerLow,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: theme.colorScheme.primary.withValues(alpha: 0.72),
          child: Center(
            child: Icon(
              Icons.description_outlined,
              size: 72,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        );
      },
    );
  }
}

class _DocumentDetailError extends StatelessWidget {
  const _DocumentDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.couldNotLoadDocumentDetails,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retryAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
