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
                child: Image.network(
                  repository.buildDocumentThumbnailUri(document.id).toString(),
                  headers: repository.buildAuthenticatedHeaders(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return ColoredBox(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
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
                ),
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
  bool _isCreatingTag = false;

  bool get _isMutatingOptions =>
      _isCreatingCorrespondent || _isCreatingDocumentType || _isCreatingTag;

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
    final selectedTagNames = tags.maybeWhen(
      data: (items) => items
          .where((item) => _selectedTagIds.contains(item.id))
          .map((item) => item.name)
          .toList(growable: false),
      orElse: () => widget.document.tags.map((tagId) => '#$tagId').toList(),
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
                data: (items) => DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _selectedCorrespondentId,
                  decoration: InputDecoration(
                    hintText: l10n.chooseCorrespondentHint,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        l10n.noCorrespondentOption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...items.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCorrespondentId = value;
                          });
                        },
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
                data: (items) => DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: _selectedDocumentTypeId,
                  decoration: InputDecoration(
                    hintText: l10n.chooseDocumentTypeHint,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        l10n.noDocumentTypeOption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...items.map(
                      (item) => DropdownMenuItem<int?>(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDocumentTypeId = value;
                          });
                        },
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
              _FieldActionHeader(
                title: l10n.tagsLabel,
                actionLabel: _isCreatingTag
                    ? l10n.addingAction
                    : l10n.newTagAction,
                actionIcon: _isCreatingTag
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                onActionPressed: _isBusy || _isCreatingTag ? null : _createTag,
              ),
              const SizedBox(height: 8),
              if (selectedTagNames.isEmpty)
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
                    for (final tagName in selectedTagNames)
                      Chip(label: Text(tagName)),
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

  Future<void> _openTagSelection(List<PaperlessFilterOption> tags) async {
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) {
        final localSelection = <int>{..._selectedTagIds};

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.selectTagsDialogTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in tags)
                      CheckboxListTile(
                        value: localSelection.contains(tag.id),
                        title: Text(tag.name),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              localSelection.add(tag.id);
                            } else {
                              localSelection.remove(tag.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.l10n.cancelAction),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(<int>{}),
                  child: Text(context.l10n.clearAction),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(localSelection),
                  child: Text(context.l10n.applyAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedTagIds = result;
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

  Future<void> _createTag() async {
    final name = await _promptForNewOption(
      title: context.l10n.newTagAction,
      fieldLabel: context.l10n.tagNameLabel,
    );
    if (name == null) {
      return;
    }

    setState(() {
      _isCreatingTag = true;
    });

    try {
      final created = await ref
          .read(documentsRepositoryProvider)
          .createTag(name: name);
      final _ = await ref.refresh(tagOptionsProvider.future);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedTagIds = <int>{..._selectedTagIds, created.id};
      });
      _showStatusMessage(context.l10n.tagCreated);
    } catch (error) {
      _showStatusMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTag = false;
        });
      }
    }
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
      ref.invalidate(todoDocumentsProvider);
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
