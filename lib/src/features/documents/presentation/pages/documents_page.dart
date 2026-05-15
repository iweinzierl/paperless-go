import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_saved_view.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/batch_document_edit_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_filters_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/selected_document_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/document_delete_selection_action.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/document_selection_banner.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_list_item.dart';

enum _DocumentsPageAction { refresh }

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({
    this.openDrawerOnLoad = false,
    this.drawerUserCardSubtitleOverride,
    super.key,
  });

  final bool openDrawerOnLoad;
  final String? drawerUserCardSubtitleOverride;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  DateTime? _lastUpdatedAt;
  DateTime? _lastRefreshFailedAt;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _lastUpdatedAt = ref
        .read(syncStatusPreferencesProvider)
        .readLastSuccessfulSync(SyncStatusScope.documents);
    if (widget.openDrawerOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _scaffoldKey.currentState?.openDrawer();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    ref.listen<AsyncValue<PaperlessDocumentPage>>(documentsPageProvider, (
      previous,
      next,
    ) {
      if (!mounted) {
        return;
      }

      if (next.hasValue) {
        final timestamp = DateTime.now();
        setState(() {
          _lastUpdatedAt = timestamp;
          _lastRefreshFailedAt = null;
        });
        unawaited(
          ref
              .read(syncStatusPreferencesProvider)
              .saveLastSuccessfulSync(SyncStatusScope.documents, timestamp),
        );
        return;
      }

      if (next.hasError) {
        setState(() {
          _lastRefreshFailedAt = DateTime.now();
        });
      }
    });

    final documentsPage = ref.watch(documentsPageProvider);
    final page = documentsPage.valueOrNull;
    final query = ref.watch(documentsSearchQueryProvider);
    final activeSavedView = ref.watch(activeSavedViewProvider);
    final ordering = ref.watch(documentsOrderingProvider);
    final filterState = ref.watch(documentsFilterStateProvider);
    final layoutMode = ref.watch(documentsLayoutModeProvider);
    final selectedIds = ref.watch(documentsSelectionProvider);
    final deletingIds = ref.watch(documentDeleteControllerProvider);
    final isSelectionActive = selectedIds.isNotEmpty;
    final selectedDocuments =
        page?.results
            .where((document) => selectedIds.contains(document.id))
            .toList(growable: false) ??
        const <PaperlessDocument>[];
    final isDeletingSelection = selectedDocuments.any(
      (document) => deletingIds.contains(document.id),
    );
    final activeFilterCount = activeSavedView == null
        ? _activeFilterCount(filterState, ordering)
        : 0;

    _syncController(activeSavedView == null ? query : '');

    final isWideScreen = useWideLayout(context);
    final effectiveLayoutMode = isWideScreen
        ? DocumentsLayoutMode.list
        : layoutMode;

    final bodyContent = ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWideScreen && isSelectionActive) ...[
                  DocumentSelectionBanner(
                    count: selectedIds.length,
                    onClear: _clearSelection,
                    onEdit: selectedDocuments.isEmpty || isDeletingSelection
                        ? null
                        : () => _editSelectedDocuments(
                            context,
                            selectedDocuments,
                          ),
                    onDelete: selectedDocuments.isEmpty
                        ? null
                        : () => _deleteSelectedDocuments(
                            context,
                            selectedDocuments,
                          ),
                    isDeleting: isDeletingSelection,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submitSearch,
                        decoration: InputDecoration(
                          hintText: l10n.searchByTitleHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  tooltip: l10n.clearSearchTooltip,
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.outlined(
                      tooltip: l10n.filtersTooltip,
                      onPressed: () => _openFilters(context),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: theme.colorScheme.surfaceContainer,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      icon: Badge.count(
                        isLabelVisible: activeFilterCount > 0,
                        count: activeFilterCount,
                        child: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
                if (activeSavedView != null) ...[
                  const SizedBox(height: 12),
                  _ActiveSavedViewChip(
                    savedView: activeSavedView,
                    onClear: _clearActiveSavedViewSelection,
                  ),
                ],
                if (activeFilterCount > 0) ...[
                  const SizedBox(height: 12),
                  _ActiveDocumentsControls(
                    filterState: filterState,
                    ordering: ordering,
                    onRemoveTag: (tagId) => _updateFilters(
                      filterState.copyWith(
                        tagIds: filterState.tagIds
                            .where((currentTagId) => currentTagId != tagId)
                            .toList(growable: false),
                        clearTag: filterState.tagIds.length == 1,
                      ),
                    ),
                    onClearCorrespondent: filterState.correspondentId != null
                        ? () => _updateFilters(
                            filterState.copyWith(clearCorrespondent: true),
                          )
                        : null,
                    onClearDocumentType: filterState.documentTypeId != null
                        ? () => _updateFilters(
                            filterState.copyWith(clearDocumentType: true),
                          )
                        : null,
                    onResetOrdering:
                        ordering != documentsSortOptions.first.ordering
                        ? () => _updateOrdering(
                            documentsSortOptions.first.ordering,
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshDocumentsPage,
                  child: page != null
                      ? _DocumentsList(
                          page: page,
                          layoutMode: effectiveLayoutMode,
                          lastUpdatedAt: _lastUpdatedAt,
                          isRefreshing: documentsPage.isRefreshing,
                          lastRefreshFailedAt: _lastRefreshFailedAt,
                          onPreviousPage:
                              page.count > 0 &&
                                  ref.read(documentsCurrentPageProvider) > 1
                              ? () => _goToPage(
                                  ref.read(documentsCurrentPageProvider) - 1,
                                )
                              : null,
                          onNextPage:
                              (ref.read(documentsCurrentPageProvider) * 20) <
                                  page.count
                              ? () => _goToPage(
                                  ref.read(documentsCurrentPageProvider) + 1,
                                )
                              : null,
                        )
                      : documentsPage.when(
                          data: (_) => const SizedBox.shrink(),
                          error: (error, stackTrace) => _DocumentsError(
                            onRetry: () =>
                                ref.invalidate(documentsPageProvider),
                          ),
                          loading: () => const _DocumentsLoading(),
                        ),
                ),
                if (documentsPage.isRefreshing && page != null)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWideScreen
          ? null
          : AppDrawer(
              userCardSubtitleOverride: widget.drawerUserCardSubtitleOverride,
            ),
      appBar: isWideScreen
          ? null
          : AppBar(
              titleSpacing: 0,
              title: Text(
                isSelectionActive
                    ? _selectionTitle(selectedIds.length)
                    : l10n.navigationDocuments,
              ),
              actions: isSelectionActive
                  ? [
                      IconButton(
                        tooltip: 'Batch edit',
                        onPressed:
                            selectedDocuments.isEmpty || isDeletingSelection
                            ? null
                            : () => _editSelectedDocuments(
                                context,
                                selectedDocuments,
                              ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: l10n.deleteAction,
                        onPressed:
                            selectedDocuments.isEmpty || isDeletingSelection
                            ? null
                            : () => _deleteSelectedDocuments(
                                context,
                                selectedDocuments,
                              ),
                        icon: isDeletingSelection
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                      ),
                      IconButton(
                        tooltip: l10n.clearSearchTooltip,
                        onPressed: isDeletingSelection ? null : _clearSelection,
                        icon: const Icon(Icons.close),
                      ),
                    ]
                  : [
                      IconButton(
                        onPressed: () =>
                            _updateLayoutMode(_nextLayoutMode(layoutMode)),
                        icon: Icon(_layoutModeIcon(layoutMode)),
                      ),
                      PopupMenuButton<_DocumentsPageAction>(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).showMenuTooltip,
                        onSelected: (action) {
                          switch (action) {
                            case _DocumentsPageAction.refresh:
                              _refreshDocumentsPage();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<_DocumentsPageAction>(
                            value: _DocumentsPageAction.refresh,
                            enabled: !documentsPage.isRefreshing,
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).refreshIndicatorSemanticLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
            ),
      body: isWideScreen
          ? SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: 8),
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: bodyContent),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      flex: 2,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final selectedId = ref.watch(
                            selectedDocumentIdProvider,
                          );
                          if (selectedId == null) {
                            return Center(
                              child: Text(
                                l10n.documentDetailsTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return DocumentDetailPage(
                            documentId: selectedId,
                            embedded: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : bodyContent,
    );
  }

  void _submitSearch(String value) {
    _clearSelection();
    _clearActiveSavedViewSelection();
    ref.read(documentsSearchQueryProvider.notifier).state = value.trim();
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _clearSearch() {
    _searchController.clear();
    _clearSelection();
    _clearActiveSavedViewSelection();
    ref.read(documentsSearchQueryProvider.notifier).state = '';
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _goToPage(int page) {
    _clearSelection();
    ref.read(documentsCurrentPageProvider.notifier).state = page;
  }

  void _updateFilters(DocumentsFilterState nextState) {
    _clearSelection();
    _clearActiveSavedViewSelection();
    ref.read(documentsFilterStateProvider.notifier).state = nextState;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _updateOrdering(String? ordering) {
    if (ordering == null) {
      return;
    }

    _clearSelection();
    _clearActiveSavedViewSelection();
    ref.read(documentsOrderingProvider.notifier).state = ordering;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _updateLayoutMode(DocumentsLayoutMode mode) {
    if (ref.read(documentsLayoutModeProvider) == mode) {
      return;
    }

    if (mode == DocumentsLayoutMode.card) {
      _clearSelection();
    }

    ref.read(documentsLayoutModeProvider.notifier).state = mode;
    unawaited(ref.read(documentsViewPreferencesProvider).saveLayoutMode(mode));
  }

  void _clearSelection() {
    ref.read(documentsSelectionProvider.notifier).state = <int>{};
  }

  Future<void> _deleteSelectedDocuments(
    BuildContext context,
    List<PaperlessDocument> documents,
  ) async {
    await confirmAndDeleteSelectedDocuments(
      context: context,
      ref: ref,
      documents: documents,
      onDeleted: _clearSelection,
    );
  }

  Future<void> _editSelectedDocuments(
    BuildContext context,
    List<PaperlessDocument> documents,
  ) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => BatchDocumentEditPage(documents: documents),
      ),
    );

    if (didUpdate == true) {
      _clearSelection();
    }
  }

  DocumentsLayoutMode _nextLayoutMode(DocumentsLayoutMode mode) {
    return switch (mode) {
      DocumentsLayoutMode.card => DocumentsLayoutMode.list,
      DocumentsLayoutMode.list => DocumentsLayoutMode.compactList,
      DocumentsLayoutMode.compactList => DocumentsLayoutMode.card,
    };
  }

  IconData _layoutModeIcon(DocumentsLayoutMode mode) {
    return switch (mode) {
      DocumentsLayoutMode.card => Icons.view_list_rounded,
      DocumentsLayoutMode.list => Icons.view_headline_rounded,
      DocumentsLayoutMode.compactList => Icons.dashboard_customize_rounded,
    };
  }

  void _syncController(String query) {
    if (_searchController.text == query) {
      return;
    }

    _searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  Future<void> _refreshDocumentsPage() async {
    final _ = await ref.refresh(documentsPageProvider.future);
  }

  Future<void> _openFilters(BuildContext context) async {
    final activeSavedView = ref.read(activeSavedViewProvider);
    final result = await Navigator.of(context).push<DocumentsFiltersResult>(
      MaterialPageRoute<DocumentsFiltersResult>(
        builder: (context) => DocumentsFiltersPage(
          initialFilterState: activeSavedView == null
              ? ref.read(documentsFilterStateProvider)
              : const DocumentsFilterState(),
          initialOrdering: activeSavedView == null
              ? ref.read(documentsOrderingProvider)
              : documentsSortOptions.first.ordering,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    _clearSelection();
    _clearActiveSavedViewSelection();
    ref.read(documentsFilterStateProvider.notifier).state = result.filterState;
    ref.read(documentsOrderingProvider.notifier).state = result.ordering;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _clearActiveSavedViewSelection() {
    if (ref.read(activeSavedViewIdProvider) == null) {
      return;
    }

    ref.read(activeSavedViewIdProvider.notifier).state = null;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  int _activeFilterCount(DocumentsFilterState filterState, String ordering) {
    var count = 0;
    if (filterState.tagIds.isNotEmpty) {
      count += 1;
    }
    if (filterState.correspondentId != null) {
      count += 1;
    }
    if (filterState.documentTypeId != null) {
      count += 1;
    }
    if (ordering != documentsSortOptions.first.ordering) {
      count += 1;
    }

    return count;
  }

  String _selectionTitle(int count) {
    return '$count selected';
  }
}

class _ActiveSavedViewChip extends StatelessWidget {
  const _ActiveSavedViewChip({required this.savedView, required this.onClear});

  final PaperlessSavedView savedView;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: const Icon(Icons.bookmarks_outlined, size: 18),
        label: Text(l10n.documentsActiveSavedView(savedView.name)),
        onDeleted: onClear,
        deleteIcon: const Icon(Icons.close),
      ),
    );
  }
}

class _ActiveDocumentsControls extends ConsumerWidget {
  const _ActiveDocumentsControls({
    required this.filterState,
    required this.ordering,
    required this.onRemoveTag,
    required this.onClearCorrespondent,
    required this.onClearDocumentType,
    required this.onResetOrdering,
  });

  final DocumentsFilterState filterState;
  final String ordering;
  final void Function(int tagId) onRemoveTag;
  final VoidCallback? onClearCorrespondent;
  final VoidCallback? onClearDocumentType;
  final VoidCallback? onResetOrdering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tagOptions = ref.watch(tagOptionsProvider);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final chips = <Widget>[];

    if (ordering != documentsSortOptions.first.ordering) {
      final sortLabel = documentsSortOptions
          .where((option) => option.ordering == ordering)
          .firstOrNull
          ?.ordering;
      if (sortLabel != null) {
        chips.add(
          InputChip(
            label: Text(documentSortOptionLabel(l10n, sortLabel)),
            onDeleted: onResetOrdering,
            deleteIcon: const Icon(Icons.close),
          ),
        );
      }
    }

    for (final tagId in filterState.tagIds) {
      _addFilterChip(
        chips: chips,
        optionId: tagId,
        options: tagOptions,
        fallbackPrefix: l10n.filterTagLabel,
        onDeleted: () => onRemoveTag(tagId),
      );
    }
    _addFilterChip(
      chips: chips,
      optionId: filterState.correspondentId,
      options: correspondentOptions,
      fallbackPrefix: l10n.filterCorrespondentLabel,
      onDeleted: onClearCorrespondent,
    );
    _addFilterChip(
      chips: chips,
      optionId: filterState.documentTypeId,
      options: documentTypeOptions,
      fallbackPrefix: l10n.filterDocumentTypeLabel,
      onDeleted: onClearDocumentType,
    );

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  void _addFilterChip({
    required List<Widget> chips,
    required int? optionId,
    required AsyncValue<List<PaperlessFilterOption>> options,
    required String fallbackPrefix,
    required VoidCallback? onDeleted,
  }) {
    if (optionId == null) {
      return;
    }

    final label = options.maybeWhen(
      data: (items) =>
          items.where((item) => item.id == optionId).firstOrNull?.name,
      orElse: () => null,
    );

    chips.add(
      InputChip(
        label: Text(label ?? '$fallbackPrefix #$optionId'),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close),
      ),
    );
  }
}

class _DocumentsList extends ConsumerWidget {
  const _DocumentsList({
    required this.page,
    required this.layoutMode,
    required this.lastUpdatedAt,
    required this.isRefreshing,
    required this.lastRefreshFailedAt,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final PaperlessDocumentPage page;
  final DocumentsLayoutMode layoutMode;
  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final DateTime? lastRefreshFailedAt;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentPage = ref.watch(documentsCurrentPageProvider);
    final openingIds = ref.watch(documentOpenControllerProvider);
    final selectedIds = ref.watch(documentsSelectionProvider);
    final l10n = context.l10n;
    final isSelectionActive = selectedIds.isNotEmpty;

    if (page.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                l10n.noDocumentsMatchSearch,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final countLabel = Text(
              l10n.documentCount(page.count),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
            final refreshStatus = RefreshStatusText(
              lastUpdatedAt: lastUpdatedAt,
              isRefreshing: isRefreshing,
              lastRefreshFailedAt: lastRefreshFailedAt,
            );

            if (constraints.maxWidth < 280) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  countLabel,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: refreshStatus),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: countLabel),
                const SizedBox(width: 12),
                refreshStatus,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        for (final document in page.results) ...[
          if (layoutMode == DocumentsLayoutMode.card)
            PaperlessDocumentCard(
              document: document,
              onTap: () => _openDetails(context, ref, document),
              footer: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: FilledButton(
                      onPressed: openingIds.contains(document.id)
                          ? null
                          : () => _openDocument(context, ref, document),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        openingIds.contains(document.id)
                            ? l10n.openingAction
                            : l10n.openAction,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => _openDetails(context, ref, document),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(116, 52),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.detailsAction),
                  ),
                ],
              ),
            )
          else
            PaperlessDocumentListItem(
              document: document,
              showPreview: layoutMode == DocumentsLayoutMode.list,
              isSelected: selectedIds.contains(document.id),
              onTap: () {
                if (isSelectionActive) {
                  _toggleSelection(ref, document.id);
                  return;
                }

                _openDetails(context, ref, document);
              },
              onLongPress: () => _selectDocument(ref, document.id),
              onLeadingIconPressed: () => _toggleSelection(ref, document.id),
            ),
          SizedBox(height: layoutMode == DocumentsLayoutMode.card ? 12 : 10),
        ],
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: onPreviousPage,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.pageIndicator(currentPage),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNextPage,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openDetails(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
  ) {
    ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
    final isWideScreen = useWideLayout(context);
    if (isWideScreen) {
      ref.read(selectedDocumentIdProvider.notifier).state = document.id;
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DocumentDetailPage(documentId: document.id),
        ),
      );
    }
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
  ) async {
    try {
      ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
      await ref
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _selectDocument(WidgetRef ref, int documentId) {
    final selectedIds = ref.read(documentsSelectionProvider);
    if (selectedIds.contains(documentId)) {
      return;
    }

    ref.read(documentsSelectionProvider.notifier).state = <int>{
      ...selectedIds,
      documentId,
    };
  }

  void _toggleSelection(WidgetRef ref, int documentId) {
    final selectedIds = ref.read(documentsSelectionProvider);
    final nextSelection = <int>{...selectedIds};
    if (!nextSelection.add(documentId)) {
      nextSelection.remove(documentId);
    }

    ref.read(documentsSelectionProvider.notifier).state = nextSelection;
  }
}

class _DocumentsError extends StatelessWidget {
  const _DocumentsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(context.l10n.couldNotLoadDocuments),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.retryAction),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsLoading extends StatelessWidget {
  const _DocumentsLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
