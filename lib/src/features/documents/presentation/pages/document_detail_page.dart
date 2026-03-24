import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/document_text.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({required this.documentId, super.key});

  final int documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.documentDetailsTitle)),
      body: documentAsync.when(
        data: (document) => _DocumentDetailBody(document: document),
        error: (error, stackTrace) => _DocumentDetailError(
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DocumentDetailBody extends ConsumerWidget {
  const _DocumentDetailBody({required this.document});

  final PaperlessDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openingIds = ref.watch(documentOpenControllerProvider);
    final isOpening = openingIds.contains(document.id);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final session = ref.watch(authSessionProvider);
    final repository = ref.watch(documentsRepositoryProvider);
    final thumbnailWidget = repository.buildDocumentThumbnailWidget(document);
    final thumbnailImageProvider = repository
        .buildDocumentThumbnailImageProvider(document.id);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final tagOptions = ref.watch(tagOptionsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatDocumentSubtitle(
                              l10n: l10n,
                              localeName: context.localeName,
                              id: document.id,
                              added: document.added,
                              created: document.created,
                              pageCount: document.pageCount,
                              archiveSerialNumber: document.archiveSerialNumber,
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _editMetadata(context, ref, document),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.editMetadataAction),
                    ),
                    FilledButton.icon(
                      onPressed: isOpening
                          ? null
                          : () => _openDocument(context, ref, document),
                      icon: Icon(
                        isOpening ? Icons.hourglass_top : Icons.open_in_new,
                      ),
                      label: Text(
                        isOpening
                            ? l10n.openingAction
                            : l10n.openDocumentAction,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isOpening
                          ? null
                          : () => _openDocument(
                              context,
                              ref,
                              document,
                              original: true,
                            ),
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text(l10n.openOriginalAction),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: l10n.thumbnailPreviewTitle,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child:
                    thumbnailWidget ??
                    (thumbnailImageProvider != null
                        ? Image(
                            image: thumbnailImageProvider,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            repository
                                .buildDocumentThumbnailUri(document.id)
                                .toString(),
                            headers: repository.buildAuthenticatedHeaders(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return ColoredBox(
                                color: theme.colorScheme.surfaceContainerLow,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(l10n.noThumbnailPreviewAvailable),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.authenticatedThumbnailRequest(session.serverUrl),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: l10n.metadataTitle,
          children: [
            _DetailRow(
              label: l10n.fileNameLabel,
              value: document.preferredFileName,
            ),
            _DetailRow(label: l10n.mimeTypeLabel, value: document.mimeType),
            _DetailRow(
              label: l10n.createdLabel,
              value: _formatMetadataTimestamp(context, document.created),
            ),
            _DetailRow(
              label: l10n.addedLabel,
              value: _formatMetadataTimestamp(context, document.added),
            ),
            _DetailRow(
              label: l10n.pagesLabel,
              value: document.pageCount?.toString(),
            ),
            _DetailRow(
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
              Text(document.content!.trim(), style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ],
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _DetailSection(
            title: l10n.editableFieldsTitle,
            children: [
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.titleLabel,
                  errorText: _titleError,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _createdController,
                decoration: InputDecoration(
                  labelText: l10n.createdDateLabel,
                  hintText: l10n.createdDateHint,
                  errorText: _createdError,
                  suffixIcon: IconButton(
                    onPressed: _isBusy ? null : _pickCreatedDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldActionHeader(
                title: l10n.correspondentLabel,
                actionLabel: _isCreatingCorrespondent
                    ? l10n.addingAction
                    : l10n.newCorrespondentAction,
                actionIcon: _isCreatingCorrespondent
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                onActionPressed: _isBusy || _isCreatingCorrespondent
                    ? null
                    : _createCorrespondent,
              ),
              const SizedBox(height: 8),
              correspondents.when(
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedCorrespondentLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InputChip(
                          label: Text(selectedCorrespondentLabel),
                          onDeleted: _isBusy
                              ? null
                              : () => setState(() {
                                  _selectedCorrespondentId = null;
                                }),
                          deleteIcon: const Icon(Icons.close),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.noCorrespondentOption,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: _isBusy
                          ? null
                          : () => _openCorrespondentSelection(items),
                      icon: const Icon(Icons.person_search_outlined),
                      label: Text(l10n.chooseCorrespondentHint),
                    ),
                  ],
                ),
                error: (error, stackTrace) => Text(
                  l10n.couldNotLoadCorrespondents,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
              ),
              const SizedBox(height: 16),
              _FieldActionHeader(
                title: l10n.documentTypeLabel,
                actionLabel: _isCreatingDocumentType
                    ? l10n.addingAction
                    : l10n.newDocumentTypeAction,
                actionIcon: _isCreatingDocumentType
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                onActionPressed: _isBusy || _isCreatingDocumentType
                    ? null
                    : _createDocumentType,
              ),
              const SizedBox(height: 8),
              documentTypes.when(
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedDocumentTypeLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InputChip(
                          label: Text(selectedDocumentTypeLabel),
                          onDeleted: _isBusy
                              ? null
                              : () => setState(() {
                                  _selectedDocumentTypeId = null;
                                }),
                          deleteIcon: const Icon(Icons.close),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.noDocumentTypeOption,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: _isBusy
                          ? null
                          : () => _openDocumentTypeSelection(items),
                      icon: const Icon(Icons.find_in_page_outlined),
                      label: Text(l10n.chooseDocumentTypeHint),
                    ),
                  ],
                ),
                error: (error, stackTrace) => Text(
                  l10n.couldNotLoadDocumentTypes,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.tagsLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedTags.isEmpty)
                Text(
                  l10n.noTagsSelected,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in selectedTags)
                      InputChip(
                        label: Text(tag.value),
                        onDeleted: _isBusy
                            ? null
                            : () => _removeSelectedTag(tag.key),
                        deleteIcon: const Icon(Icons.close),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              tags.when(
                data: (items) => FilledButton.tonalIcon(
                  onPressed: _isBusy ? null : () => _openTagSelection(items),
                  icon: const Icon(Icons.sell_outlined),
                  label: Text(l10n.editTagsAction),
                ),
                error: (error, stackTrace) => OutlinedButton.icon(
                  onPressed: _isBusy
                      ? null
                      : () => ref.invalidate(tagOptionsProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryTagLoadingAction),
                ),
                loading: () => const LinearProgressIndicator(),
              ),
            ],
          ),
        ],
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
    final name = await _promptForNewOption(
      title: context.l10n.newCorrespondentAction,
      fieldLabel: context.l10n.correspondentNameLabel,
    );
    if (name == null) {
      return;
    }

    setState(() {
      _isCreatingCorrespondent = true;
    });

    try {
      final created = await ref
          .read(documentsRepositoryProvider)
          .createCorrespondent(name: name);
      final _ = await ref.refresh(correspondentOptionsProvider.future);

      if (!mounted) {
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
    final name = await _promptForNewOption(
      title: context.l10n.newDocumentTypeAction,
      fieldLabel: context.l10n.documentTypeNameLabel,
    );
    if (name == null) {
      return;
    }

    setState(() {
      _isCreatingDocumentType = true;
    });

    try {
      final created = await ref
          .read(documentsRepositoryProvider)
          .createDocumentType(name: name);
      final _ = await ref.refresh(documentTypeOptionsProvider.future);

      if (!mounted) {
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
        return _DetailRow(
          label: label,
          value: match?.name ?? fallbackValue ?? optionId.toString(),
        );
      },
      error: (error, stackTrace) =>
          _DetailRow(label: label, value: fallbackValue ?? optionId.toString()),
      loading: () =>
          _DetailRow(label: label, value: context.l10n.loadingStatus),
    );
  }
}

class _FieldActionHeader extends StatelessWidget {
  const _FieldActionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onActionPressed,
  });

  final String title;
  final String actionLabel;
  final Widget actionIcon;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onActionPressed,
          icon: actionIcon,
          label: Text(actionLabel),
        ),
      ],
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
  });

  final String title;
  final String searchHint;
  final String emptyOptionLabel;
  final String noResultsMessage;
  final List<PaperlessFilterOption> options;
  final int? selectedId;

  @override
  State<_SingleOptionSelectionSheet> createState() =>
      _SingleOptionSelectionSheetState();
}

class _SingleOptionSelectionSheetState
    extends State<_SingleOptionSelectionSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
    final filtered = widget.options.where((option) {
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
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    widget.selectedId == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
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
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
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
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
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
        return _DetailRow(
          label: context.l10n.tagsLabel,
          value: names.join(', '),
        );
      },
      error: (error, stackTrace) => _DetailRow(
        label: context.l10n.tagsLabel,
        value: document.tags.join(', '),
      ),
      loading: () => _DetailRow(
        label: context.l10n.tagsLabel,
        value: context.l10n.loadingStatus,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 420;

          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value!, style: theme.textTheme.bodyMedium),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Text(value!, style: theme.textTheme.bodyMedium)),
            ],
          );
        },
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.couldNotLoadDocumentDetails),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retryAction),
            ),
          ],
        ),
      ),
    );
  }
}
