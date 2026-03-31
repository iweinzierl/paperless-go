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
    final hasActiveSelections =
        _filterState.hasActiveFilters ||
        _ordering != documentsSortOptions.first.ordering;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          '${l10n.filtersTitle} & ${l10n.sortByLabel}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: isWideScreen
          ? _buildWideLayout(
              context,
              theme,
              l10n,
              hasActiveSelections,
              tagOptions,
              correspondentOptions,
              documentTypeOptions,
            )
          : _buildCompactLayout(
              context,
              theme,
              l10n,
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
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerLowest,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalInset = constraints.maxWidth > 800
              ? (constraints.maxWidth - 800) / 2
              : 0.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              18 + horizontalInset,
              14,
              18 + horizontalInset,
              156,
            ),
            children: _buildCompactSections(
              l10n,
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
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerLowest,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
                    if (hasActiveSelections) ...[
                      _SectionTitle(title: l10n.filtersTitle),
                      const SizedBox(height: 14),
                      _ActiveFiltersWrap(
                        filterState: _filterState,
                        ordering: _ordering,
                        tagOptions: tagOptions,
                        correspondentOptions: correspondentOptions,
                        documentTypeOptions: documentTypeOptions,
                        onRemoveTag: _removeTag,
                        onClearCorrespondent: _clearCorrespondent,
                        onClearDocumentType: _clearDocumentType,
                        onResetOrdering: _resetOrdering,
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 360,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: l10n.sortByLabel),
                              const SizedBox(height: 14),
                              _SortOptionsGrid(
                                selectedOrdering: _ordering,
                                compact: true,
                                onChanged: (value) {
                                  setState(() {
                                    _ordering = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(title: l10n.filtersTitle),
                              const SizedBox(height: 14),
                              _SingleFilterCategoryCard(
                                title: l10n.filterCorrespondentLabel,
                                icon: Icons.business_outlined,
                                iconBackgroundColor: const Color(0xFFD6EAF9),
                                options: correspondentOptions,
                                selectedId: _filterState.correspondentId,
                                searchHint: l10n.searchCorrespondentsHint,
                                dialogTitle:
                                    l10n.selectCorrespondentDialogTitle,
                                noResultsMessage:
                                    l10n.noCorrespondentsMatchSearch,
                                onChanged: _setCorrespondent,
                              ),
                              const SizedBox(height: 16),
                              _SingleFilterCategoryCard(
                                title: l10n.filterDocumentTypeLabel,
                                icon: Icons.description_outlined,
                                iconBackgroundColor: const Color(0xFFFFDDD3),
                                options: documentTypeOptions,
                                selectedId: _filterState.documentTypeId,
                                searchHint: l10n.searchDocumentTypesHint,
                                dialogTitle: l10n.selectDocumentTypeDialogTitle,
                                noResultsMessage:
                                    l10n.noDocumentTypesMatchSearch,
                                onChanged: _setDocumentType,
                              ),
                              const SizedBox(height: 16),
                              _TagCategoryCard(
                                options: tagOptions,
                                selectedIds: _filterState.tagIds,
                                searchHint: l10n.searchTagsHint,
                                dialogTitle: l10n.selectTagsDialogTitle,
                                noResultsMessage: l10n.noTagsMatchSearch,
                                onChanged: _setTags,
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
    bool hasActiveSelections,
    AsyncValue<List<PaperlessFilterOption>> tagOptions,
    AsyncValue<List<PaperlessFilterOption>> correspondentOptions,
    AsyncValue<List<PaperlessFilterOption>> documentTypeOptions,
  ) {
    return [
      if (hasActiveSelections) ...[
        _SectionTitle(title: l10n.filtersTitle),
        const SizedBox(height: 14),
        _ActiveFiltersWrap(
          filterState: _filterState,
          ordering: _ordering,
          tagOptions: tagOptions,
          correspondentOptions: correspondentOptions,
          documentTypeOptions: documentTypeOptions,
          onRemoveTag: _removeTag,
          onClearCorrespondent: _clearCorrespondent,
          onClearDocumentType: _clearDocumentType,
          onResetOrdering: _resetOrdering,
        ),
        const SizedBox(height: 28),
      ],
      _SectionTitle(title: l10n.sortByLabel),
      const SizedBox(height: 14),
      _SortOptionsGrid(
        selectedOrdering: _ordering,
        onChanged: (value) {
          setState(() {
            _ordering = value;
          });
        },
      ),
      const SizedBox(height: 28),
      _SectionTitle(title: l10n.filtersTitle),
      const SizedBox(height: 14),
      _SingleFilterCategoryCard(
        title: l10n.filterCorrespondentLabel,
        icon: Icons.business_outlined,
        iconBackgroundColor: const Color(0xFFD6EAF9),
        options: correspondentOptions,
        selectedId: _filterState.correspondentId,
        searchHint: l10n.searchCorrespondentsHint,
        dialogTitle: l10n.selectCorrespondentDialogTitle,
        noResultsMessage: l10n.noCorrespondentsMatchSearch,
        onChanged: _setCorrespondent,
      ),
      const SizedBox(height: 16),
      _SingleFilterCategoryCard(
        title: l10n.filterDocumentTypeLabel,
        icon: Icons.description_outlined,
        iconBackgroundColor: const Color(0xFFFFDDD3),
        options: documentTypeOptions,
        selectedId: _filterState.documentTypeId,
        searchHint: l10n.searchDocumentTypesHint,
        dialogTitle: l10n.selectDocumentTypeDialogTitle,
        noResultsMessage: l10n.noDocumentTypesMatchSearch,
        onChanged: _setDocumentType,
      ),
      const SizedBox(height: 16),
      _TagCategoryCard(
        options: tagOptions,
        selectedIds: _filterState.tagIds,
        searchHint: l10n.searchTagsHint,
        dialogTitle: l10n.selectTagsDialogTitle,
        noResultsMessage: l10n.noTagsMatchSearch,
        onChanged: _setTags,
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
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
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
                        if (hasActiveSelections) ...[
                          TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: Text(l10n.resetAction),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _ActionButtonsRow(
                            onCancel: () => Navigator.of(context).maybePop(),
                            onApply: _apply,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasActiveSelections) ...[
                          TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: Text(l10n.resetAction),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _ActionButtonsRow(
                          onCancel: () => Navigator.of(context).maybePop(),
                          onApply: _apply,
                        ),
                      ],
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

  void _resetOrdering() {
    setState(() {
      _ordering = documentsSortOptions.first.ordering;
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
              minimumSize: const Size.fromHeight(66),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.cancelAction.toUpperCase(),
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
              minimumSize: const Size.fromHeight(66),
              shape: const StadiumBorder(),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    l10n.applyFiltersAction.toUpperCase(),
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
        fontWeight: FontWeight.w800,
        letterSpacing: 1.7,
      ),
    );
  }
}

class _ActiveFiltersWrap extends StatelessWidget {
  const _ActiveFiltersWrap({
    required this.filterState,
    required this.ordering,
    required this.tagOptions,
    required this.correspondentOptions,
    required this.documentTypeOptions,
    required this.onRemoveTag,
    required this.onClearCorrespondent,
    required this.onClearDocumentType,
    required this.onResetOrdering,
  });

  final DocumentsFilterState filterState;
  final String ordering;
  final AsyncValue<List<PaperlessFilterOption>> tagOptions;
  final AsyncValue<List<PaperlessFilterOption>> correspondentOptions;
  final AsyncValue<List<PaperlessFilterOption>> documentTypeOptions;
  final void Function(int tagId) onRemoveTag;
  final VoidCallback onClearCorrespondent;
  final VoidCallback onClearDocumentType;
  final VoidCallback onResetOrdering;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[];

    if (ordering != documentsSortOptions.first.ordering) {
      chips.add(
        _FilterChip(
          label: documentSortOptionLabel(l10n, ordering),
          tint: const Color(0xFFE3EFFC),
          onRemoved: onResetOrdering,
        ),
      );
    }

    for (final tagId in filterState.tagIds) {
      chips.add(
        _FilterChip(
          label:
              '${l10n.filterTagLabel}: ${_resolveOptionLabel(tagOptions, tagId) ?? '#$tagId'}',
          tint: const Color(0xFFE1F7F2),
          onRemoved: () => onRemoveTag(tagId),
        ),
      );
    }

    if (filterState.correspondentId != null) {
      chips.add(
        _FilterChip(
          label:
              '${l10n.filterCorrespondentLabel}: ${_resolveOptionLabel(correspondentOptions, filterState.correspondentId!) ?? '#${filterState.correspondentId}'}',
          tint: const Color(0xFFE3EFFC),
          onRemoved: onClearCorrespondent,
        ),
      );
    }

    if (filterState.documentTypeId != null) {
      chips.add(
        _FilterChip(
          label:
              '${l10n.filterDocumentTypeLabel}: ${_resolveOptionLabel(documentTypeOptions, filterState.documentTypeId!) ?? '#${filterState.documentTypeId}'}',
          tint: const Color(0xFFFFE7DF),
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
    required this.onRemoved,
  });

  final String label;
  final Color tint;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onRemoved,
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOptionsGrid extends StatelessWidget {
  const _SortOptionsGrid({
    required this.selectedOrdering,
    required this.onChanged,
    this.compact = false,
  });

  final String selectedOrdering;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentsSortOptions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: compact ? 12 : 14,
        crossAxisSpacing: compact ? 12 : 14,
        childAspectRatio: compact ? 2.9 : 2.45,
      ),
      itemBuilder: (context, index) {
        final option = documentsSortOptions[index];
        final isSelected = option.ordering == selectedOrdering;

        return _SortOptionButton(
          label: _compactSortLabel(context, option.ordering),
          selected: isSelected,
          onTap: () => onChanged(option.ordering),
        );
      },
    );
  }
}

class _SortOptionButton extends StatelessWidget {
  const _SortOptionButton({
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
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
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
          iconBackgroundColor: const Color(0xFFA9F0E4),
          title: context.l10n.filterTagLabel,
          subtitle: selectedNames.isEmpty
              ? searchHint
              : _selectedSummary(selectedNames),
          badgeLabel: selectedIds.isEmpty
              ? context.l10n.anyOption.toUpperCase()
              : '${selectedIds.length}',
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
        iconBackgroundColor: const Color(0xFFA9F0E4),
        title: context.l10n.filterTagLabel,
        subtitle: context.l10n.couldNotLoadStatus,
      ),
      loading: () => _CategoryCard.loading(
        icon: Icons.local_offer_outlined,
        iconBackgroundColor: const Color(0xFFA9F0E4),
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
          subtitle: selectedName ?? searchHint,
          badgeLabel: selectedName == null
              ? context.l10n.anyOption.toUpperCase()
              : '1',
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
    required this.badgeLabel,
    required this.onTap,
  }) : loading = false;

  const _CategoryCard.loading({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
  }) : badgeLabel = null,
       onTap = null,
       loading = true;

  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(28),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 28, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
                if (badgeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
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

String _compactSortLabel(BuildContext context, String ordering) {
  return documentSortOptionLabel(context.l10n, ordering);
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
