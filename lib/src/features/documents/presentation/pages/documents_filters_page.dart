import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isWideScreen = useWideLayout(context);
    final tagOptions = ref.watch(tagOptionsProvider);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final hasActiveFilters = _filterState.hasActiveFilters;
    final hasActiveSelections =
        hasActiveFilters || _ordering != documentsSortOptions.first.ordering;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          '${l10n.filtersTitle} & ${l10n.sortByLabel}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (hasActiveSelections)
            TextButton(
              onPressed: _reset,
              child: Text(
                l10n.resetAction,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: isWideScreen
          ? _buildWideLayout(
              context,
              theme,
              l10n,
              hasActiveFilters,
              hasActiveSelections,
              tagOptions,
              correspondentOptions,
              documentTypeOptions,
            )
          : _buildCompactLayout(
              context,
              theme,
              l10n,
              hasActiveFilters,
              hasActiveSelections,
              tagOptions,
              correspondentOptions,
              documentTypeOptions,
            ),
      bottomNavigationBar: _buildBottomActionBar(
        context,
        theme,
        l10n,
        isWideScreen: isWideScreen,
        hasActiveSelections: hasActiveSelections,
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool hasActiveFilters,
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalInset = constraints.maxWidth > 800
              ? (constraints.maxWidth - 800) / 2
              : 0.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              24 + horizontalInset,
              20,
              24 + horizontalInset,
              148,
            ),
            children: _buildCompactSections(
              l10n,
              hasActiveFilters,
              hasActiveSelections,
              tagOptions,
              correspondentOptions,
              documentTypeOptions,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool hasActiveFilters,
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasActiveFilters) ...[
                      _SectionTitle(title: l10n.filtersTitle),
                      const SizedBox(height: 12),
                      _ActiveFiltersWrap(
                        filterState: _filterState,
                        tagOptions: tagOptions,
                        correspondentOptions: correspondentOptions,
                        documentTypeOptions: documentTypeOptions,
                        onRemoveTag: _removeTag,
                        onClearCorrespondent: _clearCorrespondent,
                        onClearDocumentType: _clearDocumentType,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: l10n.filtersTitle),
                              const SizedBox(height: 14),
                              ..._buildFilterCards(
                                l10n,
                                tagOptions,
                                correspondentOptions,
                                documentTypeOptions,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 344,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: l10n.sortByLabel),
                              const SizedBox(height: 12),
                              _SortSectionCard(
                                ordering: _ordering,
                                onChanged: (value) {
                                  setState(() {
                                    _ordering = value;
                                  });
                                },
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCompactSections(
    AppLocalizations l10n,
    bool hasActiveFilters,
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return [
      if (hasActiveFilters) ...[
        _SectionTitle(title: l10n.filtersTitle),
        const SizedBox(height: 12),
        _ActiveFiltersWrap(
          filterState: _filterState,
          tagOptions: tagOptions,
          correspondentOptions: correspondentOptions,
          documentTypeOptions: documentTypeOptions,
          onRemoveTag: _removeTag,
          onClearCorrespondent: _clearCorrespondent,
          onClearDocumentType: _clearDocumentType,
        ),
        const SizedBox(height: 24),
      ],
      _SectionTitle(title: l10n.sortByLabel),
      const SizedBox(height: 12),
      _SortSectionCard(
        ordering: _ordering,
        onChanged: (value) {
          setState(() {
            _ordering = value;
          });
        },
      ),
      const SizedBox(height: 28),
      _SectionTitle(title: l10n.filtersTitle),
      const SizedBox(height: 14),
      ..._buildFilterCards(
        l10n,
        tagOptions,
        correspondentOptions,
        documentTypeOptions,
      ),
    ];
  }

  List<Widget> _buildFilterCards(
    AppLocalizations l10n,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return [
      _FilterOptionsSection(
        children: [
          _TagCategoryCard(
            options: tagOptions,
            selectedIds: _filterState.tagIds,
            searchHint: l10n.searchTagsHint,
            dialogTitle: l10n.selectTagsDialogTitle,
            noResultsMessage: l10n.noTagsMatchSearch,
            onChanged: _setTags,
          ),
          _SingleFilterCategoryCard(
            title: l10n.filterCorrespondentLabel,
            icon: Icons.business_outlined,
            iconBackgroundColor: const Color(0xFFDDF6EE),
            options: correspondentOptions,
            selectedId: _filterState.correspondentId,
            searchHint: l10n.searchCorrespondentsHint,
            dialogTitle: l10n.selectCorrespondentDialogTitle,
            noResultsMessage: l10n.noCorrespondentsMatchSearch,
            onChanged: _setCorrespondent,
          ),
          _SingleFilterCategoryCard(
            title: l10n.filterDocumentTypeLabel,
            icon: Icons.description_outlined,
            iconBackgroundColor: const Color(0xFFF5E8FF),
            options: documentTypeOptions,
            selectedId: _filterState.documentTypeId,
            searchHint: l10n.searchDocumentTypesHint,
            dialogTitle: l10n.selectDocumentTypeDialogTitle,
            noResultsMessage: l10n.noDocumentTypesMatchSearch,
            onChanged: _setDocumentType,
          ),
        ],
      ),
    ];
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    required bool isWideScreen,
    required bool hasActiveSelections,
  }) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = isWideScreen ? 1080.0 : 800.0;
            final horizontalInset = constraints.maxWidth > maxContentWidth
                ? (constraints.maxWidth - maxContentWidth) / 2
                : 0.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18 + horizontalInset,
                14,
                18 + horizontalInset,
                18,
              ),
              child: isWideScreen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _ActionButtonsRow(
                            onCancel: () => Navigator.of(context).maybePop(),
                            onApply: _apply,
                          ),
                        ),
                      ],
                    )
                  : _ActionButtonsRow(
                      onCancel: () => Navigator.of(context).maybePop(),
                      onApply: _apply,
                    ),
            );
          },
        ),
      ),
    );
  }

  void _clearCorrespondent() {
    setState(() {
      _filterState = _filterState.copyWith(clearCorrespondent: true);
    });
  }

  void _clearDocumentType() {
    setState(() {
      _filterState = _filterState.copyWith(clearDocumentType: true);
    });
  }

  void _removeTag(int tagId) {
    setState(() {
      final nextTagIds = _filterState.tagIds
          .where((selectedId) => selectedId != tagId)
          .toList(growable: false);
      _filterState = _filterState.copyWith(
        tagIds: nextTagIds,
        clearTag: nextTagIds.isEmpty,
      );
    });
  }

  void _setCorrespondent(int? value) {
    setState(() {
      _filterState = _filterState.copyWith(
        correspondentId: value,
        clearCorrespondent: value == null,
      );
    });
  }

  void _setDocumentType(int? value) {
    setState(() {
      _filterState = _filterState.copyWith(
        documentTypeId: value,
        clearDocumentType: value == null,
      );
    });
  }

  void _setTags(List<int> value) {
    setState(() {
      _filterState = _filterState.copyWith(
        tagIds: value,
        clearTag: value.isEmpty,
      );
    });
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

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({required this.onCancel, required this.onApply});

  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.cancelAction,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 7,
          child: FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.applyFiltersAction,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _ActiveFiltersWrap extends StatelessWidget {
  const _ActiveFiltersWrap({
    required this.filterState,
    required this.tagOptions,
    required this.correspondentOptions,
    required this.documentTypeOptions,
    required this.onRemoveTag,
    required this.onClearCorrespondent,
    required this.onClearDocumentType,
  });

  final DocumentsFilterState filterState;
  final AsyncValue<List<PaperlessFilterOption>> tagOptions;
  final AsyncValue<List<PaperlessFilterOption>> correspondentOptions;
  final AsyncValue<List<PaperlessFilterOption>> documentTypeOptions;
  final void Function(int tagId) onRemoveTag;
  final VoidCallback onClearCorrespondent;
  final VoidCallback onClearDocumentType;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    for (final tagId in filterState.tagIds) {
      chips.add(
        _FilterChip(
          label: _resolveOptionLabel(tagOptions, tagId) ?? '#$tagId',
          tint: const Color(0xFFE0E8FF),
          icon: Icons.local_offer_outlined,
          onRemoved: () => onRemoveTag(tagId),
        ),
      );
    }

    if (filterState.correspondentId != null) {
      chips.add(
        _FilterChip(
          label:
              _resolveOptionLabel(
                correspondentOptions,
                filterState.correspondentId!,
              ) ??
              '#${filterState.correspondentId}',
          tint: const Color(0xFFF0F3F7),
          icon: Icons.business_outlined,
          onRemoved: onClearCorrespondent,
        ),
      );
    }

    if (filterState.documentTypeId != null) {
      chips.add(
        _FilterChip(
          label:
              _resolveOptionLabel(
                documentTypeOptions,
                filterState.documentTypeId!,
              ) ??
              '#${filterState.documentTypeId}',
          tint: const Color(0xFFF6ECFF),
          icon: Icons.description_outlined,
          onRemoved: onClearDocumentType,
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 12, children: chips);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.tint,
    required this.icon,
    required this.onRemoved,
  });

  final String label;
  final Color tint;
  final IconData icon;
  final VoidCallback onRemoved;

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
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemoved,
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortSectionCard extends StatelessWidget {
  const _SortSectionCard({
    required this.ordering,
    required this.onChanged,
    this.compact = false,
  });

  final String ordering;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = _sortFieldForOrdering(ordering);
    final descending = _isDescendingOrdering(ordering);
    const fields = <String>['created', 'added', 'title'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < fields.length; index++) ...[
                _PrimarySortOptionRow(
                  label: _sortFieldLabel(context, fields[index]),
                  selected: field == fields[index],
                  onTap: () => onChanged(
                    _orderingFor(
                      fields[index],
                      field == fields[index]
                          ? descending
                          : _defaultDescendingForField(fields[index]),
                    ),
                  ),
                ),
                if (index != fields.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: _SortDirectionToggle(
                  field: field,
                  descending: descending,
                  onChanged: (value) => onChanged(_orderingFor(field, value)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOptionsSection extends StatelessWidget {
  const _FilterOptionsSection({required this.children});

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
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _SortDirectionToggle extends StatelessWidget {
  const _SortDirectionToggle({
    required this.field,
    required this.descending,
    required this.onChanged,
  });

  final String field;
  final bool descending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.surface;
    final inactiveColor = theme.colorScheme.surfaceContainerLow;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: inactiveColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _SortDirectionButton(
                selected: descending,
                backgroundColor: activeColor,
                label: _sortDirectionLabel(context, _orderingFor(field, true)),
                tooltip: documentSortOptionLabel(
                  context.l10n,
                  _orderingFor(field, true),
                ),
                icon: field == 'title'
                    ? Icons.sort_by_alpha_rounded
                    : Icons.south_rounded,
                onTap: () => onChanged(true),
              ),
            ),
            Expanded(
              child: _SortDirectionButton(
                selected: !descending,
                backgroundColor: activeColor,
                label: _sortDirectionLabel(context, _orderingFor(field, false)),
                tooltip: documentSortOptionLabel(
                  context.l10n,
                  _orderingFor(field, false),
                ),
                icon: field == 'title'
                    ? Icons.sort_by_alpha_rounded
                    : Icons.north_rounded,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDirectionButton extends StatelessWidget {
  const _SortDirectionButton({
    required this.selected,
    required this.backgroundColor,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final Color backgroundColor;
  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
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

class _TagCategoryCard extends StatelessWidget {
  const _TagCategoryCard({
    required this.options,
    required this.selectedIds,
    required this.searchHint,
    required this.dialogTitle,
    required this.noResultsMessage,
    required this.onChanged,
  });

  final AsyncValue<List<PaperlessFilterOption>> options;
  final List<int> selectedIds;
  final String searchHint;
  final String dialogTitle;
  final String noResultsMessage;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        final selectedNames = items
            .where((item) => selectedIds.contains(item.id))
            .map((item) => item.name)
            .toList(growable: false);

        return _CategoryCard(
          icon: Icons.local_offer_outlined,
          iconBackgroundColor: const Color(0xFFE8F0FF),
          title: context.l10n.filterTagLabel,
          subtitle: selectedNames.isEmpty
              ? context.l10n.anyOption
              : _selectedSummary(selectedNames),
          onTap: () async {
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
        );
      },
      error: (error, stackTrace) => _CategoryCard.loading(
        icon: Icons.local_offer_outlined,
        iconBackgroundColor: const Color(0xFFE8F0FF),
        title: context.l10n.filterTagLabel,
        subtitle: context.l10n.couldNotLoadStatus,
      ),
      loading: () => _CategoryCard.loading(
        icon: Icons.local_offer_outlined,
        iconBackgroundColor: const Color(0xFFE8F0FF),
        title: context.l10n.filterTagLabel,
        subtitle: context.l10n.loadingStatus,
      ),
    );
  }
}

class _SingleFilterCategoryCard extends StatelessWidget {
  const _SingleFilterCategoryCard({
    required this.title,
    required this.icon,
    required this.iconBackgroundColor,
    required this.options,
    required this.selectedId,
    required this.searchHint,
    required this.dialogTitle,
    required this.noResultsMessage,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color iconBackgroundColor;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final int? selectedId;
  final String searchHint;
  final String dialogTitle;
  final String noResultsMessage;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        final selectedName = items
            .where((item) => item.id == selectedId)
            .firstOrNull
            ?.name;

        return _CategoryCard(
          icon: icon,
          iconBackgroundColor: iconBackgroundColor,
          title: title,
          subtitle: selectedName ?? context.l10n.anyOption,
          onTap: () async {
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
        );
      },
      error: (error, stackTrace) => _CategoryCard.loading(
        icon: icon,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        subtitle: context.l10n.couldNotLoadStatus,
      ),
      loading: () => _CategoryCard.loading(
        icon: icon,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        subtitle: context.l10n.loadingStatus,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : loading = false;

  const _CategoryCard.loading({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
  }) : onTap = null,
       loading = true;

  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 30,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _sortFieldForOrdering(String ordering) {
  return ordering.startsWith('-') ? ordering.substring(1) : ordering;
}

bool _isDescendingOrdering(String ordering) {
  return ordering.startsWith('-');
}

String _orderingFor(String field, bool descending) {
  return descending ? '-$field' : field;
}

String _sortFieldLabel(BuildContext context, String field) {
  final l10n = context.l10n;
  return switch (field) {
    'created' => l10n.createdDateLabel,
    'added' => _sortFieldSegment(documentSortOptionLabel(l10n, '-added')),
    'title' => _sortFieldSegment(documentSortOptionLabel(l10n, 'title')),
    _ => field,
  };
}

String _sortFieldSegment(String label) {
  final separatorIndex = label.indexOf(' (');
  if (separatorIndex <= 0) {
    return label;
  }
  return label.substring(0, separatorIndex);
}

String _sortDirectionLabel(BuildContext context, String ordering) {
  final label = documentSortOptionLabel(context.l10n, ordering);
  final start = label.indexOf('(');
  final end = label.lastIndexOf(')');
  if (start == -1 || end == -1 || end <= start + 1) {
    return label;
  }
  return label.substring(start + 1, end);
}

String? _resolveOptionLabel(
  AsyncValue<List<PaperlessFilterOption>> options,
  int id,
) {
  return options.maybeWhen(
    data: (items) => items.where((item) => item.id == id).firstOrNull?.name,
    orElse: () => null,
  );
}

String _selectedSummary(List<String> names) {
  if (names.isEmpty) {
    return '';
  }
  if (names.length <= 2) {
    return names.join(', ');
  }

  return '${names.take(2).join(', ')} +${names.length - 2}';
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
                _SelectableOptionRow(
                  label: widget.anyLabel,
                  selected: widget.selectedId == null,
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

                            return _SelectableOptionRow(
                              label: option.name,
                              selected: isSelected,
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

                            return _CheckboxOptionRow(
                              label: option.name,
                              selected: isSelected,
                              onChanged: (checked) =>
                                  _toggleOption(option.id, checked),
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

class _PrimarySortOptionRow extends StatelessWidget {
  const _PrimarySortOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionRow extends StatelessWidget {
  const _SelectableOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxOptionRow extends StatelessWidget {
  const _CheckboxOptionRow({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value == true),
              ),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

bool _defaultDescendingForField(String field) {
  return switch (field) {
    'title' => false,
    _ => true,
  };
}
