import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/scan_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentUploads = ref.watch(recentUploadsProvider);
    final l10n = context.l10n;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeRefreshTooltip,
            onPressed: recentUploads.isRefreshing
                ? null
                : () => _refreshHome(context, ref),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const _RecentUploadsTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanDocument(context),
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(l10n.scanDocumentAction),
      ),
    );
  }

  Future<void> _openScanDocument(BuildContext context) async {
    final taskId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (context) => const ScanDocumentPage()),
    );

    if (!context.mounted || taskId == null || taskId.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.scanDocumentQueued)));
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
}

class _RecentUploadsTab extends ConsumerStatefulWidget {
  const _RecentUploadsTab();

  @override
  ConsumerState<_RecentUploadsTab> createState() => _RecentUploadsTabState();
}

class _RecentUploadsTabState extends ConsumerState<_RecentUploadsTab> {
  DateTime? _lastUpdatedAt;
  DateTime? _lastRefreshFailedAt;

  @override
  void initState() {
    super.initState();
    _lastUpdatedAt = ref
        .read(syncStatusPreferencesProvider)
        .readLastSuccessfulSync(SyncStatusScope.recentUploads);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.refresh(recentUploadsProvider.future),
          child: documents != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: RefreshStatusText(
                        lastUpdatedAt: _lastUpdatedAt,
                        isRefreshing: recentUploads.isRefreshing,
                        lastRefreshFailedAt: _lastRefreshFailedAt,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (documents.isEmpty)
                      _EmptyStateCard(
                        title: l10n.noUploadsYetTitle,
                        description: l10n.noUploadsYetDescription,
                      ),
                    for (final document in documents) ...[
                      PaperlessDocumentCard(
                        document: document,
                        onTap: () =>
                            _openDocumentDetails(context, ref, document),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                )
              : recentUploads.when(
                  data: (_) => const SizedBox.shrink(),
                  error: (error, stackTrace) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: RefreshStatusText(
                            lastUpdatedAt: _lastUpdatedAt,
                            isRefreshing: recentUploads.isRefreshing,
                            lastRefreshFailedAt: _lastRefreshFailedAt,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: RefreshStatusText(
                            lastUpdatedAt: _lastUpdatedAt,
                            isRefreshing: recentUploads.isRefreshing,
                            lastRefreshFailedAt: _lastRefreshFailedAt,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _LoadingCard(),
                      ],
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
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
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
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
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
