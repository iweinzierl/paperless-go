import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_list_item.dart';

enum _ReviewQueuePageAction { refresh }

class ReviewQueuePage extends ConsumerStatefulWidget {
  const ReviewQueuePage({super.key});

  @override
  ConsumerState<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends ConsumerState<ReviewQueuePage> {
  DateTime? _lastUpdatedAt;
  DateTime? _lastRefreshFailedAt;

  @override
  void initState() {
    super.initState();
    _lastUpdatedAt = ref
        .read(syncStatusPreferencesProvider)
        .readLastSuccessfulSync(SyncStatusScope.todoDocuments);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final layoutMode = ref.watch(documentsLayoutModeProvider);
    final openingIds = ref.watch(documentOpenControllerProvider);

    ref.listen<AsyncValue<List<PaperlessDocument>>>(reviewDocumentsProvider, (
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
              .saveLastSuccessfulSync(SyncStatusScope.todoDocuments, timestamp),
        );
        return;
      }

      if (next.hasError) {
        setState(() {
          _lastRefreshFailedAt = DateTime.now();
        });
      }
    });

    final reviewDocuments = ref.watch(reviewDocumentsProvider);
    final documents = reviewDocuments.valueOrNull;

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

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(l10n.navigationInbox),
        actions: [
          IconButton(
            onPressed: () => _updateLayoutMode(
              layoutMode == DocumentsLayoutMode.card
                  ? DocumentsLayoutMode.list
                  : DocumentsLayoutMode.card,
            ),
            icon: Icon(
              layoutMode == DocumentsLayoutMode.card
                  ? Icons.view_list_rounded
                  : Icons.dashboard_customize_rounded,
            ),
          ),
          PopupMenuButton<_ReviewQueuePageAction>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) {
              switch (action) {
                case _ReviewQueuePageAction.refresh:
                  _refreshReviewQueue();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_ReviewQueuePageAction>(
                value: _ReviewQueuePageAction.refresh,
                enabled: !reviewDocuments.isRefreshing,
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHigh,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(reviewDocumentsProvider.future),
              child: documents != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: RefreshStatusText(
                            lastUpdatedAt: _lastUpdatedAt,
                            isRefreshing: reviewDocuments.isRefreshing,
                            lastRefreshFailedAt: _lastRefreshFailedAt,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (documents.isEmpty)
                          _ReviewEmptyStateCard(
                            title: l10n.nothingToReviewTitle,
                            description: l10n.nothingToReviewDescription,
                          ),
                        for (final document in documents) ...[
                          if (layoutMode == DocumentsLayoutMode.card)
                            PaperlessDocumentCard(
                              document: document,
                              onTap: () =>
                                  _openDocumentDetails(context, ref, document),
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
                                        minimumSize: const Size.fromHeight(58),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        shape: const StadiumBorder(),
                                        textStyle: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                      child: Text(
                                        (openingIds.contains(document.id)
                                                ? l10n.openingAction
                                                : l10n.openAction)
                                            .toUpperCase(),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _openDocumentDetails(
                                      context,
                                      ref,
                                      document,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                      textStyle: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    child: Text(
                                      l10n.detailsAction.toUpperCase(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            PaperlessDocumentListItem(
                              document: document,
                              onTap: () =>
                                  _openDocumentDetails(context, ref, document),
                              isOpening: openingIds.contains(document.id),
                              onOpen: () =>
                                  _openDocument(context, ref, document),
                            ),
                          SizedBox(
                            height: layoutMode == DocumentsLayoutMode.card
                                ? 18
                                : 10,
                          ),
                        ],
                      ],
                    )
                  : reviewDocuments.when(
                      data: (_) => const SizedBox.shrink(),
                      error: (error, stackTrace) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: RefreshStatusText(
                                lastUpdatedAt: _lastUpdatedAt,
                                isRefreshing: reviewDocuments.isRefreshing,
                                lastRefreshFailedAt: _lastRefreshFailedAt,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReviewEmptyStateCard(
                              title: l10n.couldNotLoadReviewQueueTitle,
                              description:
                                  l10n.couldNotLoadReviewQueueDescription,
                            ),
                          ],
                        );
                      },
                      loading: () {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: RefreshStatusText(
                                lastUpdatedAt: _lastUpdatedAt,
                                isRefreshing: reviewDocuments.isRefreshing,
                                lastRefreshFailedAt: _lastRefreshFailedAt,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _ReviewLoadingCard(),
                          ],
                        );
                      },
                    ),
            ),
            if (reviewDocuments.isRefreshing && documents != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  void _openDocumentDetails(
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _refreshReviewQueue() async {
    final _ = await ref.refresh(reviewDocumentsProvider.future);
  }

  void _updateLayoutMode(DocumentsLayoutMode mode) {
    if (ref.read(documentsLayoutModeProvider) == mode) {
      return;
    }

    ref.read(documentsLayoutModeProvider.notifier).state = mode;
    unawaited(ref.read(documentsViewPreferencesProvider).saveLayoutMode(mode));
  }
}

class _ReviewLoadingCard extends StatelessWidget {
  const _ReviewLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ReviewEmptyStateCard extends StatelessWidget {
  const _ReviewEmptyStateCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
