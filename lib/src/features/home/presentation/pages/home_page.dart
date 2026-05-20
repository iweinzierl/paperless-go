import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/batch_document_edit_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/document_carousel_source.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_carousel_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/document_delete_selection_action.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/document_selection_banner.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_list_item.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/selected_document_provider.dart';

enum _HomePageAction { refresh }

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentUploads = ref.watch(recentUploadsProvider);
    final l10n = context.l10n;
    final layoutMode = ref.watch(documentsLayoutModeProvider);
    final selectedIds = ref.watch(recentUploadsSelectionProvider);
    final deletingIds = ref.watch(documentDeleteControllerProvider);
    final isSelectionActive = selectedIds.isNotEmpty;
    final documents = recentUploads.valueOrNull;
    final selectedDocuments =
        documents
            ?.where((document) => selectedIds.contains(document.id))
            .toList(growable: false) ??
        const <PaperlessDocument>[];
    final isDeletingSelection = selectedDocuments.any(
      (document) => deletingIds.contains(document.id),
    );
    final isWideScreen = useWideLayout(context);

    final bodyContent = const _RecentUploadsTab();

    return Scaffold(
      drawer: isWideScreen ? null : const AppDrawer(),
      appBar: isWideScreen
          ? null
          : AppBar(
              title: Text(
                isSelectionActive
                    ? _selectionTitle(selectedIds.length)
                    : l10n.navigationRecent,
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
                                ref,
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
                                ref,
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
                        onPressed: isDeletingSelection
                            ? null
                            : () =>
                                  ref
                                          .read(
                                            recentUploadsSelectionProvider
                                                .notifier,
                                          )
                                          .state =
                                      <int>{},
                        icon: const Icon(Icons.close),
                      ),
                    ]
                  : [
                      IconButton(
                        onPressed: () =>
                            _updateLayoutMode(ref, _nextLayoutMode(layoutMode)),
                        icon: Icon(_layoutModeIcon(layoutMode)),
                      ),
                      PopupMenuButton<_HomePageAction>(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).showMenuTooltip,
                        onSelected: (action) {
                          switch (action) {
                            case _HomePageAction.refresh:
                              _refreshHome(context, ref);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<_HomePageAction>(
                            value: _HomePageAction.refresh,
                            enabled: !recentUploads.isRefreshing,
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
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: bodyContent),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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

  void _updateLayoutMode(WidgetRef ref, DocumentsLayoutMode mode) {
    if (ref.read(documentsLayoutModeProvider) == mode) {
      return;
    }

    if (mode == DocumentsLayoutMode.card) {
      ref.read(recentUploadsSelectionProvider.notifier).state = <int>{};
    }

    ref.read(documentsLayoutModeProvider.notifier).state = mode;
    unawaited(ref.read(documentsViewPreferencesProvider).saveLayoutMode(mode));
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

  Future<void> _refreshHome(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    try {
      final _ = await ref.refresh(recentUploadsProvider.future);

      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(context.l10n.homeUpdated)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(context.l10n.homeRefreshFailed)),
      );
    }
  }

  Future<void> _deleteSelectedDocuments(
    BuildContext context,
    WidgetRef ref,
    List<PaperlessDocument> documents,
  ) async {
    await confirmAndDeleteSelectedDocuments(
      context: context,
      ref: ref,
      documents: documents,
      onDeleted: () =>
          ref.read(recentUploadsSelectionProvider.notifier).state = <int>{},
    );
  }

  Future<void> _editSelectedDocuments(
    BuildContext context,
    WidgetRef ref,
    List<PaperlessDocument> documents,
  ) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => BatchDocumentEditPage(documents: documents),
      ),
    );

    if (didUpdate == true) {
      ref.read(recentUploadsSelectionProvider.notifier).state = <int>{};
    }
  }

  String _selectionTitle(int count) {
    return '$count selected';
  }
}

class _RecentUploadsTab extends ConsumerStatefulWidget {
  const _RecentUploadsTab();

  @override
  ConsumerState<_RecentUploadsTab> createState() => _RecentUploadsTabState();
}

class _RecentUploadsTabState extends ConsumerState<_RecentUploadsTab> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  DateTime? _lastUpdatedAt;
  DateTime? _lastRefreshFailedAt;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _lastUpdatedAt = ref
        .read(syncStatusPreferencesProvider)
        .readLastSuccessfulSync(SyncStatusScope.recentUploads);
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
    final layoutMode = ref.watch(documentsLayoutModeProvider);
    final openingIds = ref.watch(documentOpenControllerProvider);
    final isWideScreen = useWideLayout(context);
    final effectiveLayoutMode = isWideScreen
        ? DocumentsLayoutMode.list
        : layoutMode;

    ref.listen<AsyncValue<List<PaperlessDocument>>>(recentUploadsProvider, (
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
              .saveLastSuccessfulSync(SyncStatusScope.recentUploads, timestamp),
        );
        return;
      }

      if (next.hasError) {
        setState(() {
          _lastRefreshFailedAt = DateTime.now();
        });
      }
    });

    final recentUploads = ref.watch(recentUploadsProvider);
    final documents = recentUploads.valueOrNull;
    final filteredDocuments = documents
        ?.where((document) => _matchesSearchQuery(document))
        .toList(growable: false);
    final selectedIds = ref.watch(recentUploadsSelectionProvider);
    final deletingIds = ref.watch(documentDeleteControllerProvider);
    final isSelectionActive = selectedIds.isNotEmpty;
    final selectedDocuments =
        documents
            ?.where((document) => selectedIds.contains(document.id))
            .toList(growable: false) ??
        const <PaperlessDocument>[];
    final isDeletingSelection = selectedDocuments.any(
      (document) => deletingIds.contains(document.id),
    );

    if (documents != null && _lastUpdatedAt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _lastUpdatedAt != null) {
          return;
        }

        setState(() {
          _lastUpdatedAt = DateTime.now();
        });
      });
    }

    return ColoredBox(
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
                            ref,
                            selectedDocuments,
                          ),
                    onDelete: selectedDocuments.isEmpty
                        ? null
                        : () => _deleteSelectedDocuments(
                            context,
                            ref,
                            selectedDocuments,
                          ),
                    isDeleting: isDeletingSelection,
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: _updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: l10n.searchByTitleHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: l10n.clearSearchTooltip,
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                  ),
                ),
                if (isWideScreen) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: RefreshStatusText(
                      lastUpdatedAt: _lastUpdatedAt,
                      isRefreshing: recentUploads.isRefreshing,
                      lastRefreshFailedAt: _lastRefreshFailedAt,
                    ),
                  ),
                ],
                if (!isWideScreen) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: RefreshStatusText(
                      lastUpdatedAt: _lastUpdatedAt,
                      isRefreshing: recentUploads.isRefreshing,
                      lastRefreshFailedAt: _lastRefreshFailedAt,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.refresh(recentUploadsProvider.future),
                  child: documents != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            if (documents.isEmpty)
                              _EmptyStateCard(
                                title: l10n.noUploadsYetTitle,
                                description: l10n.noUploadsYetDescription,
                              )
                            else if (filteredDocuments!.isEmpty)
                              _EmptyStateCard(
                                title: l10n.noDocumentsMatchSearch,
                                description: '',
                              ),
                            for (final document in filteredDocuments!) ...[
                              if (effectiveLayoutMode ==
                                  DocumentsLayoutMode.card)
                                PaperlessDocumentCard(
                                  document: document,
                                  onTap: () {
                                    ref
                                        .read(
                                          selectedDocumentIdProvider.notifier,
                                        )
                                        .state = document
                                        .id;
                                    if (!isWideScreen) {
                                      _openDocumentDetails(
                                        context,
                                        ref,
                                        document,
                                        filteredDocuments,
                                      );
                                    }
                                  },
                                  footer: Row(
                                    children: [
                                      SizedBox(
                                        width: 148,
                                        child: FilledButton(
                                          onPressed:
                                              openingIds.contains(document.id)
                                              ? null
                                              : () => _openDocument(
                                                  context,
                                                  ref,
                                                  document,
                                                ),
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size.fromHeight(
                                              52,
                                            ),
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
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
                                        onPressed: () {
                                          ref
                                                  .read(
                                                    selectedDocumentIdProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              document.id;
                                          if (!isWideScreen) {
                                            _openDocumentDetails(
                                              context,
                                              ref,
                                              document,
                                              filteredDocuments,
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(116, 52),
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
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
                                  showPreview:
                                      effectiveLayoutMode ==
                                      DocumentsLayoutMode.list,
                                  isSelected: selectedIds.contains(document.id),
                                  onTap: () {
                                    if (isSelectionActive) {
                                      _toggleSelection(document.id);
                                      return;
                                    }

                                    ref
                                        .read(
                                          selectedDocumentIdProvider.notifier,
                                        )
                                        .state = document
                                        .id;
                                    if (!isWideScreen) {
                                      _openDocumentDetails(
                                        context,
                                        ref,
                                        document,
                                        filteredDocuments,
                                      );
                                    }
                                  },
                                  onLongPress: () =>
                                      _selectDocument(document.id),
                                  onLeadingIconPressed: () =>
                                      _toggleSelection(document.id),
                                ),
                              SizedBox(
                                height:
                                    effectiveLayoutMode ==
                                        DocumentsLayoutMode.card
                                    ? 12
                                    : 10,
                              ),
                            ],
                          ],
                        )
                      : recentUploads.when(
                          data: (_) => const SizedBox.shrink(),
                          error: (error, stackTrace) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              children: [
                                _EmptyStateCard(
                                  title: l10n.couldNotLoadRecentUploadsTitle,
                                  description:
                                      l10n.couldNotLoadRecentUploadsDescription,
                                ),
                              ],
                            );
                          },
                          loading: () {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              children: const [_LoadingCard()],
                            );
                          },
                        ),
                ),
                if (recentUploads.isRefreshing && documents != null)
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

  void _clearSearch() {
    _searchController.clear();
    _updateSearchQuery('');
  }

  void _clearSelection() {
    ref.read(recentUploadsSelectionProvider.notifier).state = <int>{};
  }

  Future<void> _deleteSelectedDocuments(
    BuildContext context,
    WidgetRef ref,
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
    WidgetRef ref,
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

  bool _matchesSearchQuery(PaperlessDocument document) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    return document.title.toLowerCase().contains(_searchQuery);
  }

  void _updateSearchQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (_searchQuery == normalized) {
      return;
    }

    _clearSelection();
    setState(() {
      _searchQuery = normalized;
    });
  }

  void _selectDocument(int documentId) {
    final selectedIds = ref.read(recentUploadsSelectionProvider);
    if (selectedIds.contains(documentId)) {
      return;
    }

    ref.read(recentUploadsSelectionProvider.notifier).state = <int>{
      ...selectedIds,
      documentId,
    };
  }

  void _toggleSelection(int documentId) {
    final selectedIds = ref.read(recentUploadsSelectionProvider);
    final nextSelection = <int>{...selectedIds};
    if (!nextSelection.add(documentId)) {
      nextSelection.remove(documentId);
    }

    ref.read(recentUploadsSelectionProvider.notifier).state = nextSelection;
  }

  void _openDocumentDetails(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document,
    List<PaperlessDocument> visibleDocuments,
  ) {
    ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
    final documentIds = visibleDocuments.map((d) => d.id).toList();
    final index = documentIds.indexOf(document.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentCarouselPage(
          documentIds: documentIds,
          initialIndex: index >= 0 ? index : 0,
          source: const RecentUploadsSource(),
        ),
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
