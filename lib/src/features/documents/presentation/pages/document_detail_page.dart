import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

enum _DocumentDetailAction { openOriginal, delete }

class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({
    required this.documentId,
    this.openEditMetadataOnLoad = false,
    super.key,
  });

  final int documentId;
  final bool openEditMetadataOnLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.documentDetailsTitle),
        actions: [
          if (document != null)
            if (isDeleting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              PopupMenuButton<_DocumentDetailAction>(
                onSelected: (action) {
                  switch (action) {
                    case _DocumentDetailAction.openOriginal:
                      _openOriginalDocument(context, ref, document);
                    case _DocumentDetailAction.delete:
                      _deleteDocument(context, ref, document);
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
        ],
      ),
      body: documentAsync.when(
        data: (document) => _DocumentDetailBody(
          document: document,
          openEditMetadataOnLoad: openEditMetadataOnLoad,
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

      navigator.pop();
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
  });

  final PaperlessDocument document;
  final bool openEditMetadataOnLoad;

  @override
  ConsumerState<_DocumentDetailBody> createState() =>
      _DocumentDetailBodyState();
}

class _DocumentDetailBodyState extends ConsumerState<_DocumentDetailBody> {
  int _selectedPage = 1;
  late final ScrollController _pageStripScrollController;
  bool _didAutoOpenMetadataEditor = false;

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
    final correspondentName = _resolveOptionName(
      correspondentOptions,
      document.correspondentId,
    );
    final documentTypeName = _resolveOptionName(
      documentTypeOptions,
      document.documentTypeId,
    );
    final tagNames = _resolveTagNames(tagOptions, document.tags);
    final summaryBadges = <String>[
      if (correspondentName != null) correspondentName,
      if (documentTypeName != null) documentTypeName,
      for (final tagName in tagNames.take(3)) tagName,
      if (tagNames.length > 3) '+${tagNames.length - 3}',
    ];
    final summaryMetadata = <Widget>[
      if (document.created != null && document.created!.trim().isNotEmpty)
        _CompactMetadataItem(
          icon: Icons.calendar_today_outlined,
          label: _formatMetadataTimestamp(context, document.created)!,
        ),
      if (document.pageCount != null)
        _CompactMetadataItem(
          icon: Icons.description_outlined,
          label: l10n.documentPages(document.pageCount!),
        ),
      if (document.mimeType != null && document.mimeType!.trim().isNotEmpty)
        _CompactMetadataItem(
          icon: Icons.layers_outlined,
          label: document.mimeType!,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _DocumentSummaryCard(
            document: document,
            badges: summaryBadges,
            metadata: summaryMetadata,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isOpening
                ? null
                : () => _openDocument(context, ref, document),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            icon: Icon(
              isOpening ? Icons.hourglass_top : Icons.visibility_outlined,
            ),
            label: Text(
              (isOpening ? l10n.openingAction : l10n.openDocumentAction)
                  .toUpperCase(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: canEditMetadata
                ? () => _editMetadata(context, ref, document)
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.editMetadataAction.toUpperCase()),
          ),
          const SizedBox(height: 20),
          _PreviewCard(
            title: l10n.thumbnailPreviewTitle,
            document: document,
            pageCount: effectivePageCount,
            selectedPage: selectedPage,
            pageStripScrollController: _pageStripScrollController,
            thumbnailWidget: thumbnailWidget,
            thumbnailImageProvider: thumbnailImageProvider,
            repository: repository,
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
                : () => _openDocument(
                    context,
                    ref,
                    document,
                    variant: DocumentOpenVariant.preview,
                  ),
          ),
          const SizedBox(height: 20),
          _MetadataCard(
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
                value: _formatMetadataTimestamp(context, document.created),
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
              _ResolvedTagsRow(document: document, options: tagOptions),
            ],
          ),
          if (document.content != null &&
              document.content!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _DetailSection(
              title: l10n.contentPreviewTitle,
              children: [
                Text(
                  document.content!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ],
            ),
          ],
        ],
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
  late int? _selectedCorrespondentId;
  late int? _selectedDocumentTypeId;
  late Set<int> _selectedTagIds;
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _createdController.dispose();
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
    final repository = ref.watch(documentsRepositoryProvider);
    final correspondents = ref.watch(correspondentOptionsProvider);
    final documentTypes = ref.watch(documentTypeOptionsProvider);
    final tags = ref.watch(tagOptionsProvider);
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
    final heroEyebrow =
        (selectedCorrespondentLabel ??
                selectedDocumentTypeLabel ??
                l10n.metadataTitle)
            .toUpperCase();
    final heroBadges = <String>[
      if (widget.document.mimeType?.trim().isNotEmpty == true)
        widget.document.mimeType!.toUpperCase(),
      if (widget.document.pageCount != null)
        l10n.documentPages(widget.document.pageCount!),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editMetadataTitle),
        actions: [
          TextButton(
            onPressed: _isBusy ? null : _save,
            child: Text(_isSaving ? l10n.savingAction : l10n.saveAction),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainerLowest,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
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
            const SizedBox(height: 18),
            _EditFieldSection(
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
            ),
            const SizedBox(height: 18),
            _EditFieldSection(
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
                        onTap: _isBusy
                            ? null
                            : () => _openDocumentTypeSelection(items),
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
            ),
            const SizedBox(height: 18),
            _EditFieldSection(
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
                  onAction: _isBusy
                      ? null
                      : () => ref.invalidate(tagOptionsProvider),
                ),
                loading: () => const _EditLoadingCard(),
              ),
            ),
            const SizedBox(height: 30),
            _EditMetadataHero(
              document: widget.document,
              repository: repository,
              eyebrow: heroEyebrow,
              badges: heroBadges,
            ),
            const SizedBox(height: 30),
            Text(
              'END OF ARCHIVE METADATA',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _save() async {
    setState(() {
      _hasSubmitted = true;
    });

    if (!_isValid) {
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

class _EditMetadataHero extends StatelessWidget {
  const _EditMetadataHero({
    required this.document,
    required this.repository,
    required this.eyebrow,
    required this.badges,
  });

  final PaperlessDocument document;
  final DocumentsRepository repository;
  final String eyebrow;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 0.74,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DocumentThumbnailImage(
                    imageUri: repository.buildDocumentThumbnailUri(document.id),
                    headers: repository.buildAuthenticatedHeaders(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.48),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          eyebrow,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          document.preferredFileName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
            height: 1.05,
          ),
        ),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map((badge) => _EditMetaBadge(label: badge))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _EditFieldSection extends StatelessWidget {
  const _EditFieldSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
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
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
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
                horizontal: 18,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.8),
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
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
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
      width: 56,
      height: 56,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
        ? theme.colorScheme.primary.withValues(alpha: 0.22)
        : theme.colorScheme.surfaceContainerHighest;
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
      side: BorderSide.none,
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
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
        borderRadius: BorderRadius.circular(18),
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
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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

  return formatDocumentTimestamp(
    context.l10n,
    trimmed,
    localeName: context.localeName,
  );
}

class _DocumentSummaryCard extends StatelessWidget {
  const _DocumentSummaryCard({
    required this.document,
    required this.badges,
    required this.metadata,
  });

  final PaperlessDocument document;
  final List<String> badges;
  final List<Widget> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: metadata),
            ],
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 18),
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

class _CompactMetadataItem extends StatelessWidget {
  const _CompactMetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Text(
              value?.trim().isNotEmpty == true ? value! : '-',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (values.isEmpty)
            Text(
              '-',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
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
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.document,
    required this.pageCount,
    required this.selectedPage,
    required this.pageStripScrollController,
    required this.thumbnailWidget,
    required this.thumbnailImageProvider,
    required this.repository,
    required this.onSelectPage,
    required this.onPreview,
  });

  final String title;
  final PaperlessDocument document;
  final int pageCount;
  final int selectedPage;
  final ScrollController pageStripScrollController;
  final Widget? thumbnailWidget;
  final ImageProvider<Object>? thumbnailImageProvider;
  final DocumentsRepository repository;
  final ValueChanged<int> onSelectPage;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewUri = repository.buildDocumentPreviewUri(
      documentId: document.id,
    );
    final headers = repository.buildAuthenticatedHeaders();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            PdfDocumentViewBuilder.uri(
              previewUri,
              headers: headers,
              builder: (context, pdfDocument) {
                if (pdfDocument == null) {
                  return _PreviewFallback(
                    document: document,
                    thumbnailWidget: thumbnailWidget,
                    thumbnailImageProvider: thumbnailImageProvider,
                    repository: repository,
                    onPreview: onPreview,
                    aspectRatio: 0.84,
                  );
                }

                final effectivePageCount = pdfDocument.pages.length;
                final effectiveSelectedPage = selectedPage.clamp(
                  1,
                  effectivePageCount,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewPanel(
                      pdfDocument: pdfDocument,
                      selectedPage: effectiveSelectedPage,
                      onPreview: onPreview,
                      aspectRatio: 0.84,
                    ),
                    const SizedBox(height: 12),
                    _PagePreviewStrip(
                      pageCount: effectivePageCount,
                      selectedPage: effectiveSelectedPage,
                      pdfDocument: pdfDocument,
                      scrollController: pageStripScrollController,
                      onPageSelected: onSelectPage,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'PAGE $effectiveSelectedPage OF $effectivePageCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loadingBuilder: (context) =>
                  _PreviewLoadingState(onPreview: onPreview, aspectRatio: 0.84),
              errorBuilder: (context, error, stackTrace) => _PreviewFallback(
                document: document,
                thumbnailWidget: thumbnailWidget,
                thumbnailImageProvider: thumbnailImageProvider,
                repository: repository,
                onPreview: onPreview,
                aspectRatio: 0.84,
              ),
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),
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
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
          child: FilledButton.tonalIcon(
            onPressed: onPreview,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.search),
            label: Text(context.l10n.openAction.toUpperCase()),
          ),
        ),
      ],
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
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    border: selected
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
          child: FilledButton.tonalIcon(
            onPressed: onPreview,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.search),
            label: Text(context.l10n.openAction.toUpperCase()),
          ),
        ),
      ],
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
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
          child: FilledButton.tonalIcon(
            onPressed: onPreview,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.search),
            label: Text(context.l10n.openAction.toUpperCase()),
          ),
        ),
      ],
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
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
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
