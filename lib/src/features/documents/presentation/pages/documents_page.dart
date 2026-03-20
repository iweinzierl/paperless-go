import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentsPage = ref.watch(documentsPageProvider);
    final session = ref.watch(authSessionProvider);
    final query = ref.watch(documentsSearchQueryProvider);
    final ordering = ref.watch(documentsOrderingProvider);
    final filterState = ref.watch(documentsFilterStateProvider);

    _syncController(query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
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
                TextField(
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
                const SizedBox(height: 12),
                _SortDropdown(
                  selectedOrdering: ordering,
                  onChanged: _updateOrdering,
                ),
                const SizedBox(height: 12),
                _DocumentsFilters(
                  filterState: filterState,
                  onTagChanged: (value) => _updateFilters(
                    filterState.copyWith(tagId: value, clearTag: value == null),
                  ),
                  onCorrespondentChanged: (value) => _updateFilters(
                    filterState.copyWith(
                      correspondentId: value,
                      clearCorrespondent: value == null,
                    ),
                  ),
                  onDocumentTypeChanged: (value) => _updateFilters(
                    filterState.copyWith(
                      documentTypeId: value,
                      clearDocumentType: value == null,
                    ),
                  ),
                  onReset: filterState.hasActiveFilters
                      ? () => _updateFilters(const DocumentsFilterState())
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Connected to ${session.serverUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: documentsPage.when(
              data: (page) => _DocumentsList(
                page: page,
                onPreviousPage:
                    page.count > 0 && ref.read(documentsCurrentPageProvider) > 1
                    ? () =>
                          _goToPage(ref.read(documentsCurrentPageProvider) - 1)
                    : null,
                onNextPage:
                    (ref.read(documentsCurrentPageProvider) * 20) < page.count
                    ? () =>
                          _goToPage(ref.read(documentsCurrentPageProvider) + 1)
                    : null,
              ),
              error: (error, stackTrace) => _DocumentsError(
                onRetry: () => ref.invalidate(documentsPageProvider),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
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
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.selectedOrdering,
    required this.onChanged,
  });

  final String selectedOrdering;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedOrdering,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sort by',
        prefixIcon: Icon(Icons.sort),
      ),
      items: documentsSortOptions
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.ordering,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DocumentsFilters extends ConsumerWidget {
  const _DocumentsFilters({
    required this.filterState,
    required this.onTagChanged,
    required this.onCorrespondentChanged,
    required this.onDocumentTypeChanged,
    required this.onReset,
  });

  final DocumentsFilterState filterState;
  final ValueChanged<int?> onTagChanged;
  final ValueChanged<int?> onCorrespondentChanged;
  final ValueChanged<int?> onDocumentTypeChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagOptionsProvider);
    final correspondents = ref.watch(correspondentOptionsProvider);
    final documentTypes = ref.watch(documentTypeOptionsProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: _FilterDropdown(
            label: 'Tag',
            selectedId: filterState.tagId,
            options: tags,
            onChanged: onTagChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: _FilterDropdown(
            label: 'Correspondent',
            selectedId: filterState.correspondentId,
            options: correspondents,
            onChanged: onCorrespondentChanged,
          ),
        ),
        SizedBox(
          width: 220,
          child: _FilterDropdown(
            label: 'Document type',
            selectedId: filterState.documentTypeId,
            options: documentTypes,
            onChanged: onDocumentTypeChanged,
          ),
        ),
        if (onReset != null)
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Reset filters'),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.selectedId,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? selectedId;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        return DropdownButtonFormField<int?>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Any')),
            ...items.map(
              (item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(item.name),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
      error: (error, stackTrace) {
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Could not load',
          ),
        );
      },
      loading: () {
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Loading...',
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No documents match the current search.'),
        ),
      );
    }

    return ListView(
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
            onTap: () => _openDetails(context, document.id),
            footer: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDetails(context, document.id),
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

  void _openDetails(BuildContext context, int documentId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentDetailPage(documentId: documentId),
      ),
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    dynamic document,
  ) async {
    try {
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
