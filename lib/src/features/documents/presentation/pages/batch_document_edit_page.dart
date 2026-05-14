import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class BatchDocumentEditPage extends ConsumerStatefulWidget {
  const BatchDocumentEditPage({required this.documents, super.key});

  final List<PaperlessDocument> documents;

  @override
  ConsumerState<BatchDocumentEditPage> createState() =>
      _BatchDocumentEditPageState();
}

class _BatchDocumentEditPageState extends ConsumerState<BatchDocumentEditPage> {
  static const int _noChangeOptionValue = -1;

  int _selectedCorrespondentId = _noChangeOptionValue;
  int _selectedDocumentTypeId = _noChangeOptionValue;
  int _selectedStoragePathId = _noChangeOptionValue;
  Set<int> _selectedTagIds = <int>{};
  bool _tagsTouched = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final storagePathOptions = ref.watch(storagePathOptionsProvider);
    final tagOptions = ref.watch(tagOptionsProvider);
    final count = widget.documents.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('Batch Edit ($count item${count == 1 ? '' : 's'})'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveAction),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _BatchInfoCard(count: count),
          const SizedBox(height: 24),
          _BatchOptionField(
            label: l10n.correspondentLabel,
            icon: Icons.business_rounded,
            options: correspondentOptions,
            value: _selectedCorrespondentId,
            onChanged: (value) {
              setState(() {
                _selectedCorrespondentId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _BatchOptionField(
            label: l10n.documentTypeLabel,
            icon: Icons.description_outlined,
            options: documentTypeOptions,
            value: _selectedDocumentTypeId,
            onChanged: (value) {
              setState(() {
                _selectedDocumentTypeId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _BatchTagsField(
            options: tagOptions,
            selectedTagIds: _selectedTagIds,
            tagsTouched: _tagsTouched,
            onEdit: () => _editTags(tagOptions.valueOrNull ?? const []),
          ),
          const SizedBox(height: 20),
          _BatchOptionField(
            label: 'Storage path',
            icon: Icons.folder_outlined,
            options: storagePathOptions,
            value: _selectedStoragePathId,
            onChanged: (value) {
              setState(() {
                _selectedStoragePathId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editTags(List<PaperlessFilterOption> options) async {
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _BatchTagSelectionSheet(
        options: options,
        initialSelection: _selectedTagIds,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedTagIds = result;
      _tagsTouched = true;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(documentsRepositoryProvider);
      final updatedDocuments = <PaperlessDocument>[];

      for (final document in widget.documents) {
        final updatedDocument = await repository.updateDocumentMetadata(
          documentId: document.id,
          title: document.title,
          created: document.created,
          correspondentId: _selectedCorrespondentId == _noChangeOptionValue
              ? document.correspondentId
              : _selectedCorrespondentId,
          documentTypeId: _selectedDocumentTypeId == _noChangeOptionValue
              ? document.documentTypeId
              : _selectedDocumentTypeId,
          storagePathId: _selectedStoragePathId == _noChangeOptionValue
              ? document.storagePathId
              : _selectedStoragePathId,
          tagIds: _tagsTouched
              ? _selectedTagIds.toList(growable: false)
              : document.tags,
        );
        updatedDocuments.add(updatedDocument);
      }

      for (final document in updatedDocuments) {
        ref.invalidate(documentDetailProvider(document.id));
        ref
            .read(recentlyOpenedDocumentsProvider.notifier)
            .refreshDocument(document);
      }
      ref.invalidate(documentsPageProvider);
      ref.invalidate(recentUploadsProvider);
      ref.invalidate(reviewDocumentsProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              updatedDocuments.length == 1
                  ? 'Updated 1 document.'
                  : 'Updated ${updatedDocuments.length} documents.',
            ),
          ),
        );
      Navigator.of(context).pop(true);
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
}

class _BatchInfoCard extends StatelessWidget {
  const _BatchInfoCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selection Summary',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your changes will be applied to $count selected documents. Fields marked as "No change" keep their current values.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchOptionField extends StatelessWidget {
  const _BatchOptionField({
    required this.label,
    required this.icon,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <DropdownMenuEntry<int>>[
      const DropdownMenuEntry<int>(
        value: _BatchDocumentEditPageState._noChangeOptionValue,
        label: 'No change',
      ),
      ...options.maybeWhen(
        data: (values) => values
            .map(
              (option) =>
                  DropdownMenuEntry<int>(value: option.id, label: option.name),
            )
            .toList(growable: false),
        orElse: () => const <DropdownMenuEntry<int>>[],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<int>(
              key: ValueKey<int>(value),
              width: constraints.maxWidth,
              enabled: !options.isLoading,
              initialSelection: value,
              leadingIcon: Icon(icon),
              errorText: options.hasError ? 'Could not load $label.' : null,
              onSelected: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
              dropdownMenuEntries: entries,
            );
          },
        ),
      ],
    );
  }
}

class _BatchTagsField extends StatelessWidget {
  const _BatchTagsField({
    required this.options,
    required this.selectedTagIds,
    required this.tagsTouched,
    required this.onEdit,
  });

  final AsyncValue<List<PaperlessFilterOption>> options;
  final Set<int> selectedTagIds;
  final bool tagsTouched;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTags = options.maybeWhen(
      data: (items) => items
          .where((item) => selectedTagIds.contains(item.id))
          .toList(growable: false),
      orElse: () => const <PaperlessFilterOption>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tagsLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!tagsTouched)
                  Text(
                    'No change',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (selectedTags.isEmpty)
                  Text(
                    'Tags will be cleared.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in selectedTags)
                        Chip(label: Text('#${tag.name}')),
                    ],
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: options.isLoading ? null : onEdit,
                  icon: const Icon(Icons.sell_outlined),
                  label: Text(
                    tagsTouched ? context.l10n.editTagsAction : 'Select tags',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Leaving tags untouched keeps each document\'s existing tags.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BatchTagSelectionSheet extends StatefulWidget {
  const _BatchTagSelectionSheet({
    required this.options,
    required this.initialSelection,
  });

  final List<PaperlessFilterOption> options;
  final Set<int> initialSelection;

  @override
  State<_BatchTagSelectionSheet> createState() =>
      _BatchTagSelectionSheetState();
}

class _BatchTagSelectionSheetState extends State<_BatchTagSelectionSheet> {
  late Set<int> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = <int>{...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredOptions = widget.options
        .where(
          (option) => option.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.selectTagsDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selection = <int>{};
                  }),
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selection),
                  child: Text(l10n.saveAction),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() {
                _query = value.trim();
              }),
              decoration: InputDecoration(
                hintText: l10n.searchTagsHint,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in filteredOptions)
                    CheckboxListTile(
                      value: _selection.contains(option.id),
                      onChanged: (_) => setState(() {
                        if (!_selection.add(option.id)) {
                          _selection.remove(option.id);
                        }
                      }),
                      title: Text(option.name),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
