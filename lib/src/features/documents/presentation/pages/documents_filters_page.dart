import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class DocumentsFiltersResult {
  const DocumentsFiltersResult({
    required this.filterState,
    required this.ordering,
  });

  final DocumentsFilterState filterState;
  final String ordering;
}

class DocumentsFiltersPage extends ConsumerStatefulWidget {
  const DocumentsFiltersPage({
    required this.initialFilterState,
    required this.initialOrdering,
    super.key,
  });

  final DocumentsFilterState initialFilterState;
  final String initialOrdering;

  @override
  ConsumerState<DocumentsFiltersPage> createState() =>
      _DocumentsFiltersPageState();
}

class _DocumentsFiltersPageState extends ConsumerState<DocumentsFiltersPage> {
  late DocumentsFilterState _filterState;
  late String _ordering;

  @override
  void initState() {
    super.initState();
    _filterState = widget.initialFilterState;
    _ordering = widget.initialOrdering;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tagOptions = ref.watch(tagOptionsProvider);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filtersTitle),
        actions: [TextButton(onPressed: _reset, child: Text(l10n.resetAction))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FiltersSection(
            title: l10n.sortByLabel,
            icon: Icons.sort,
            child: _SortSelector(
              selectedOrdering: _ordering,
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _ordering = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _FiltersSection(
            title: l10n.filterTagLabel,
            icon: Icons.label_outline,
            child: _TagFilterSection(
              label: l10n.filterTagLabel,
              selectedIds: _filterState.tagIds,
              options: tagOptions,
              searchHint: l10n.searchTagsHint,
              dialogTitle: l10n.selectTagsDialogTitle,
              noResultsMessage: l10n.noTagsMatchSearch,
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(
                    tagIds: value,
                    clearTag: value.isEmpty,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _FiltersSection(
            title: l10n.filterCorrespondentLabel,
            icon: Icons.person_outline,
            child: _FilterDropdown(
              label: l10n.filterCorrespondentLabel,
              selectedId: _filterState.correspondentId,
              options: correspondentOptions,
              searchHint: l10n.searchCorrespondentsHint,
              dialogTitle: l10n.selectCorrespondentDialogTitle,
              noResultsMessage: l10n.noCorrespondentsMatchSearch,
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(
                    correspondentId: value,
                    clearCorrespondent: value == null,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _FiltersSection(
            title: l10n.filterDocumentTypeLabel,
            icon: Icons.description_outlined,
            child: _FilterDropdown(
              label: l10n.filterDocumentTypeLabel,
              selectedId: _filterState.documentTypeId,
              options: documentTypeOptions,
              searchHint: l10n.searchDocumentTypesHint,
              dialogTitle: l10n.selectDocumentTypeDialogTitle,
              noResultsMessage: l10n.noDocumentTypesMatchSearch,
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(
                    documentTypeId: value,
                    clearDocumentType: value == null,
                  );
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FilledButton.icon(
              onPressed: _apply,
              icon: const Icon(Icons.check),
              label: Text(l10n.applyFiltersAction),
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _filterState = const DocumentsFilterState();
      _ordering = documentsSortOptions.first.ordering;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DocumentsFiltersResult(filterState: _filterState, ordering: _ordering),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SortSelector extends StatelessWidget {
  const _SortSelector({
    required this.selectedOrdering,
    required this.onChanged,
  });

  final String selectedOrdering;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selectedOption = documentsSortOptions
        .where((option) => option.ordering == selectedOrdering)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedOption == null)
          Text(
            documentSortOptionLabel(l10n, documentsSortOptions.first.ordering),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          InputChip(
            label: Text(documentSortOptionLabel(l10n, selectedOption.ordering)),
            onDeleted: selectedOrdering == documentsSortOptions.first.ordering
                ? null
                : () => onChanged(documentsSortOptions.first.ordering),
            deleteIcon: const Icon(Icons.close),
          ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              showDragHandle: true,
              builder: (dialogContext) =>
                  _SortSelectionSheet(selectedOrdering: selectedOrdering),
            );

            if (result == null || result == selectedOrdering) {
              return;
            }

            onChanged(result);
          },
          icon: const Icon(Icons.sort),
          label: Text(l10n.sortByLabel),
        ),
      ],
    );
  }
}

class _SortSelectionSheet extends StatelessWidget {
  const _SortSelectionSheet({required this.selectedOrdering});

  final String selectedOrdering;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.56,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sortByLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: documentsSortOptions.length,
                  itemBuilder: (context, index) {
                    final option = documentsSortOptions[index];
                    final isSelected = option.ordering == selectedOrdering;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(
                        documentSortOptionLabel(l10n, option.ordering),
                      ),
                      onTap: () =>
                          Navigator.of(context).pop<String>(option.ordering),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.selectedId,
    required this.options,
    required this.searchHint,
    required this.dialogTitle,
    required this.noResultsMessage,
    required this.onChanged,
  });

  final String label;
  final int? selectedId;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final String searchHint;
  final String dialogTitle;
  final String noResultsMessage;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        final theme = Theme.of(context);
        final selectedLabel = items
            .where((item) => item.id == selectedId)
            .firstOrNull
            ?.name;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedLabel == null)
              Text(
                context.l10n.anyOption,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              InputChip(
                label: Text(selectedLabel),
                onDeleted: () => onChanged(null),
                deleteIcon: const Icon(Icons.close),
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final result = await showModalBottomSheet<int?>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (dialogContext) => _SingleFilterOptionSheet(
                    title: dialogTitle,
                    searchHint: searchHint,
                    anyLabel: dialogContext.l10n.anyOption,
                    noResultsMessage: noResultsMessage,
                    options: items,
                    selectedId: selectedId,
                  ),
                );

                if (result == selectedId) {
                  return;
                }

                onChanged(result);
              },
              icon: const Icon(Icons.search),
              label: Text(searchHint),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        final l10n = context.l10n;
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.couldNotLoadStatus,
          ),
        );
      },
      loading: () {
        final l10n = context.l10n;
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.loadingStatus,
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagFilterSection extends StatelessWidget {
  const _TagFilterSection({
    required this.label,
    required this.selectedIds,
    required this.options,
    required this.searchHint,
    required this.dialogTitle,
    required this.noResultsMessage,
    required this.onChanged,
  });

  final String label;
  final List<int> selectedIds;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final String searchHint;
  final String dialogTitle;
  final String noResultsMessage;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        final theme = Theme.of(context);
        final selectedIdSet = selectedIds.toSet();
        final selectedOptions =
            items.where((item) => selectedIdSet.contains(item.id)).toList()
              ..sort(
                (left, right) =>
                    left.name.toLowerCase().compareTo(right.name.toLowerCase()),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedOptions.isEmpty)
              Text(
                context.l10n.anyOption,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in selectedOptions)
                    InputChip(
                      label: Text(option.name),
                      onDeleted: () => onChanged(
                        selectedIds
                            .where((selectedId) => selectedId != option.id)
                            .toList(growable: false),
                      ),
                      deleteIcon: const Icon(Icons.close),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final result = await showModalBottomSheet<List<int>>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (dialogContext) => _MultiFilterOptionSheet(
                    title: dialogTitle,
                    searchHint: searchHint,
                    noResultsMessage: noResultsMessage,
                    options: items,
                    selectedIds: selectedIds,
                  ),
                );

                if (result == null) {
                  return;
                }

                onChanged(result);
              },
              icon: const Icon(Icons.search),
              label: Text(searchHint),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        final l10n = context.l10n;
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.couldNotLoadStatus,
          ),
        );
      },
      loading: () {
        final l10n = context.l10n;
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: l10n.loadingStatus,
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SingleFilterOptionSheet extends StatefulWidget {
  const _SingleFilterOptionSheet({
    required this.title,
    required this.searchHint,
    required this.anyLabel,
    required this.noResultsMessage,
    required this.options,
    required this.selectedId,
  });

  final String title;
  final String searchHint;
  final String anyLabel;
  final String noResultsMessage;
  final List<PaperlessFilterOption> options;
  final int? selectedId;

  @override
  State<_SingleFilterOptionSheet> createState() =>
      _SingleFilterOptionSheetState();
}

class _SingleFilterOptionSheetState extends State<_SingleFilterOptionSheet> {
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
                  title: Text(widget.anyLabel),
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

class _MultiFilterOptionSheet extends StatefulWidget {
  const _MultiFilterOptionSheet({
    required this.title,
    required this.searchHint,
    required this.noResultsMessage,
    required this.options,
    required this.selectedIds,
  });

  final String title;
  final String searchHint;
  final String noResultsMessage;
  final List<PaperlessFilterOption> options;
  final List<int> selectedIds;

  @override
  State<_MultiFilterOptionSheet> createState() =>
      _MultiFilterOptionSheetState();
}

class _MultiFilterOptionSheetState extends State<_MultiFilterOptionSheet> {
  late final TextEditingController _searchController;
  late Set<int> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selection = widget.selectedIds.toSet();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  List<PaperlessFilterOption> get _selectedOptions {
    final selected = widget.options
        .where((option) => _selection.contains(option.id))
        .toList();
    selected.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return selected;
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

  void _toggleOption(int optionId, bool selected) {
    setState(() {
      final nextSelection = <int>{..._selection};
      if (selected) {
        nextSelection.add(optionId);
      } else {
        nextSelection.remove(optionId);
      }
      _selection = nextSelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOptions = _selectedOptions;
    final visibleOptions = _visibleOptions;
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
                if (selectedOptions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.selectedTagsSectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in selectedOptions)
                        InputChip(
                          label: Text(option.name),
                          onDeleted: () => _toggleOption(option.id, false),
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
                        context.l10n.availableTagsSectionTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_selection.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _selection = <int>{};
                        }),
                        child: Text(context.l10n.clearAction),
                      ),
                  ],
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
                            final isSelected = _selection.contains(option.id);

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(option.name),
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
                                  _toggleOption(option.id, checked == true),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancelAction),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(_selection.toList(growable: false)..sort()),
                      child: Text(context.l10n.applyAction),
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
