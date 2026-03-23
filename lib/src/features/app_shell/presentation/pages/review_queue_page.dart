import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/widgets/refresh_status_text.dart';
import 'package:paperless_ngx_app/src/core/providers/sync_status_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';

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
    final l10n = context.l10n;
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

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.verificationQueueTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeRefreshTooltip,
            onPressed: todoDocuments.isRefreshing
                ? null
                : () => _refreshReviewQueue(context),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.refresh(todoDocumentsProvider.future),
            child: documents != null
                ? ListView(
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
                      if (documents.isEmpty)
                        _ReviewEmptyStateCard(
                          title: hasConfiguredTodoTags
                              ? l10n.nothingToReviewTitle
                              : l10n.verificationQueueTitle,
                          description: hasConfiguredTodoTags
                              ? l10n.nothingToReviewDescription
                              : l10n.verificationQueueDescription,
                          actionLabel: hasConfiguredTodoTags
                              ? null
                              : l10n.openTodoTagSettingsAction,
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
                          const _ReviewLoadingCard(),
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
      ),
    );
  }

  Future<void> _refreshReviewQueue(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    try {
      final _ = await ref.refresh(todoDocumentsProvider.future);

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

class _ReviewLoadingCard extends StatelessWidget {
  const _ReviewLoadingCard();

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

class _ReviewEmptyStateCard extends StatelessWidget {
  const _ReviewEmptyStateCard({
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
