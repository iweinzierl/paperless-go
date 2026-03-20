import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_filters_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  late final TextEditingController _searchController;
  DateTime? _lastUpdatedAt;
  DateTime? _lastRefreshFailedAt;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _lastUpdatedAt = ref
        .read(syncStatusPreferencesProvider)
        .readLastSuccessfulSync(SyncStatusScope.documents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final session = ref.watch(authSessionProvider);
    final query = ref.watch(documentsSearchQueryProvider);
    final ordering = ref.watch(documentsOrderingProvider);
    final filterState = ref.watch(documentsFilterStateProvider);

    _syncController(query);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            tooltip: 'Refresh documents',
            onPressed: documentsPage.isRefreshing
                ? null
                : () => _handleManualRefresh(context),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submitSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by title',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Filters',
                      onPressed: () => _openFilters(context),
                      icon: Badge.count(
                        isLabelVisible:
                            _activeFilterCount(filterState, ordering) > 0,
                        count: _activeFilterCount(filterState, ordering),
                        child: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActiveDocumentsControls(
                  filterState: filterState,
                  ordering: ordering,
                  onClearTag: filterState.tagId != null
                      ? () =>
                            _updateFilters(filterState.copyWith(clearTag: true))
                      : null,
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
                      ? () =>
                            _updateOrdering(documentsSortOptions.first.ordering)
                      : null,
                ),
                if (_activeFilterCount(filterState, ordering) > 0)
                  const SizedBox(height: 12),
                Text(
                  'Connected to ${session.serverUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                RefreshStatusText(
                  lastUpdatedAt: _lastUpdatedAt,
                  isRefreshing: documentsPage.isRefreshing,
                  lastRefreshFailedAt: _lastRefreshFailedAt,
                ),
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
  }

  void _submitSearch(String value) {
    ref.read(documentsSearchQueryProvider.notifier).state = value.trim();
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(documentsSearchQueryProvider.notifier).state = '';
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _goToPage(int page) {
    ref.read(documentsCurrentPageProvider.notifier).state = page;
  }

  void _updateFilters(DocumentsFilterState nextState) {
    ref.read(documentsFilterStateProvider.notifier).state = nextState;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  void _updateOrdering(String? ordering) {
    if (ordering == null) {
      return;
    }

    ref.read(documentsOrderingProvider.notifier).state = ordering;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
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

  Future<void> _handleManualRefresh(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    try {
      await _refreshDocumentsPage();

      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Documents updated.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Document refresh failed.')),
      );
    }
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await Navigator.of(context).push<DocumentsFiltersResult>(
      MaterialPageRoute<DocumentsFiltersResult>(
        builder: (context) => DocumentsFiltersPage(
          initialFilterState: ref.read(documentsFilterStateProvider),
          initialOrdering: ref.read(documentsOrderingProvider),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    ref.read(documentsFilterStateProvider.notifier).state = result.filterState;
    ref.read(documentsOrderingProvider.notifier).state = result.ordering;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  int _activeFilterCount(DocumentsFilterState filterState, String ordering) {
    var count = 0;
    if (filterState.tagId != null) {
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
}

class _ActiveDocumentsControls extends ConsumerWidget {
  const _ActiveDocumentsControls({
    required this.filterState,
    required this.ordering,
    required this.onClearTag,
    required this.onClearCorrespondent,
    required this.onClearDocumentType,
    required this.onResetOrdering,
  });

  final DocumentsFilterState filterState;
  final String ordering;
  final VoidCallback? onClearTag;
  final VoidCallback? onClearCorrespondent;
  final VoidCallback? onClearDocumentType;
  final VoidCallback? onResetOrdering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagOptions = ref.watch(tagOptionsProvider);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final chips = <Widget>[];

    if (ordering != documentsSortOptions.first.ordering) {
      final sortLabel = documentsSortOptions
          .where((option) => option.ordering == ordering)
          .firstOrNull
          ?.label;
      if (sortLabel != null) {
        chips.add(
          InputChip(
            label: Text(sortLabel),
            onDeleted: onResetOrdering,
            deleteIcon: const Icon(Icons.close),
          ),
        );
      }
    }

    _addFilterChip(
      chips: chips,
      optionId: filterState.tagId,
      options: tagOptions,
      fallbackPrefix: 'Tag',
      onDeleted: onClearTag,
    );
    _addFilterChip(
      chips: chips,
      optionId: filterState.correspondentId,
      options: correspondentOptions,
      fallbackPrefix: 'Correspondent',
      onDeleted: onClearCorrespondent,
    );
    _addFilterChip(
      chips: chips,
      optionId: filterState.documentTypeId,
      options: documentTypeOptions,
      fallbackPrefix: 'Document type',
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
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final PaperlessDocumentPage page;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(documentsCurrentPageProvider);
    final openingIds = ref.watch(documentOpenControllerProvider);

    if (page.results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No documents match the current search.'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Text(
          '${page.count} documents',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final document in page.results) ...[
          PaperlessDocumentCard(
            document: document,
            onTap: () => _openDetails(context, ref, document),
            footer: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDetails(context, ref, document),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                FilledButton.tonalIcon(
                  onPressed: openingIds.contains(document.id)
                      ? null
                      : () => _openDocument(context, ref, document),
                  icon: Icon(
                    openingIds.contains(document.id)
                        ? Icons.hourglass_top
                        : Icons.open_in_new,
                  ),
                  label: Text(
                    openingIds.contains(document.id) ? 'Opening...' : 'Open',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPreviousPage,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            const Spacer(),
            Text('Page $currentPage'),
            const Spacer(),
            FilledButton.icon(
              onPressed: onNextPage,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentDetailPage(documentId: document.id),
      ),
    );
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _DocumentsError extends StatelessWidget {
  const _DocumentsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: [
        Column(
          children: [
            const Text('Could not load documents.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentsLoading extends StatelessWidget {
  const _DocumentsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      children: const [Center(child: CircularProgressIndicator())],
    );
  }
}
