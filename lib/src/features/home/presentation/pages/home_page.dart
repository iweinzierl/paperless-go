import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentUploads = ref.watch(recentUploadsProvider);
    final todoDocuments = ref.watch(todoDocumentsProvider);
    final isRefreshingHome =
        recentUploads.isRefreshing || todoDocuments.isRefreshing;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Paperless-ngx'),
          actions: [
            IconButton(
              tooltip: 'Refresh home',
              onPressed: isRefreshingHome
                  ? null
                  : () => _refreshHome(context, ref),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Log out',
              onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent uploads', icon: Icon(Icons.schedule_outlined)),
              Tab(text: 'Todos', icon: Icon(Icons.fact_check_outlined)),
            ],
          ),
        ),
        body: const TabBarView(children: [_RecentUploadsTab(), _TodosTab()]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Scan later'),
        ),
      ),
    );
  }

  Future<void> _refreshHome(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    try {
      final recentRefresh = ref.refresh(recentUploadsProvider.future);
      final todoRefresh = ref.refresh(todoDocumentsProvider.future);
      final _ = await Future.wait([recentRefresh, todoRefresh]);

      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Home updated.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Home refresh failed.')),
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
                      const _EmptyStateCard(
                        title: 'No uploads yet',
                        description:
                            'Recent documents will appear here once your server has processed uploads.',
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
                        const _EmptyStateCard(
                          title: 'Could not load recent uploads',
                          description:
                              'The home page reached your server, but document loading failed. Pull to refresh later.',
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

class _TodosTab extends ConsumerStatefulWidget {
  const _TodosTab();

  @override
  ConsumerState<_TodosTab> createState() => _TodosTabState();
}

class _TodosTabState extends ConsumerState<_TodosTab> {
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
    final behaviorSettings = ref.watch(appBehaviorSettingsProvider);
    ref.listen<AsyncValue<List<PaperlessDocument>>>(todoDocumentsProvider, (
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

    final todoDocuments = ref.watch(todoDocumentsProvider);
    final documents = todoDocuments.valueOrNull;
    final hasConfiguredTodoTags =
        behaviorSettings.normalizedTodoTagIds.isNotEmpty ||
        behaviorSettings.normalizedTodoTagNames.isNotEmpty;

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
          onRefresh: () => ref.refresh(todoDocumentsProvider.future),
          child: documents != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    const _SectionHint(
                      title: 'Verification queue',
                      description:
                          'Documents matching your configured TODO tags are listed here for manual review.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: RefreshStatusText(
                        lastUpdatedAt: _lastUpdatedAt,
                        isRefreshing: todoDocuments.isRefreshing,
                        lastRefreshFailedAt: _lastRefreshFailedAt,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (documents.isEmpty)
                      _EmptyStateCard(
                        title: hasConfiguredTodoTags
                            ? 'Nothing to review'
                            : 'No TODO tags configured',
                        description: hasConfiguredTodoTags
                            ? 'Documents with your configured TODO tags will appear here once they need manual attention.'
                            : 'Choose one or more TODO tags in Settings so documents can appear in the review queue.',
                        actionLabel: hasConfiguredTodoTags
                            ? null
                            : 'Open TODO tag settings',
                        onActionPressed: hasConfiguredTodoTags
                            ? null
                            : () => _openTodoSettings(context),
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
              : todoDocuments.when(
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
                            isRefreshing: todoDocuments.isRefreshing,
                            lastRefreshFailedAt: _lastRefreshFailedAt,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _EmptyStateCard(
                          title: 'Could not load review queue',
                          description:
                              'The app could not load documents matching your configured TODO tags right now.',
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
                            isRefreshing: todoDocuments.isRefreshing,
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
        if (todoDocuments.isRefreshing && documents != null)
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

  void _openTodoSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.title, required this.description});

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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 6),
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
  const _EmptyStateCard({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

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
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.settings_outlined),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
