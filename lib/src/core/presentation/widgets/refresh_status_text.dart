import 'package:flutter/material.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';

class RefreshStatusText extends StatelessWidget {
  const RefreshStatusText({
    super.key,
    required this.lastUpdatedAt,
    required this.isRefreshing,
    this.lastRefreshFailedAt,
  });

  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final DateTime? lastRefreshFailedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRefreshFailure = _hasRefreshFailure();
    final backgroundColor = hasRefreshFailure
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.42)
        : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.78);
    final foregroundColor = hasRefreshFailure
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          _buildLabel(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _buildLabel(BuildContext context) {
    final l10n = context.l10n;
    final localeName = context.localeName;

    if (_hasRefreshFailure()) {
      return l10n.refreshFailedLabel(
        formatRefreshTimestamp(
          l10n,
          lastRefreshFailedAt!,
          localeName: localeName,
        ),
      );
    }

    if (isRefreshing && lastUpdatedAt == null) {
      return l10n.refreshingLabel;
    }

    if (lastUpdatedAt == null) {
      return l10n.waitingForFirstSyncLabel;
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdatedAt!);
    final formattedTime = formatRefreshTimestamp(
      l10n,
      lastUpdatedAt!,
      now: now,
      localeName: localeName,
    );

    if (isRefreshing) {
      return l10n.refreshingLastUpdatedLabel(formattedTime);
    }

    if (difference < const Duration(minutes: 1)) {
      return l10n.updatedJustNowLabel;
    }

    if (difference < const Duration(hours: 1)) {
      return l10n.updatedMinutesAgo(difference.inMinutes);
    }

    return l10n.updatedAtLabel(formattedTime);
  }

  bool _hasRefreshFailure() {
    if (lastRefreshFailedAt == null) {
      return false;
    }

    if (lastUpdatedAt == null) {
      return true;
    }

    return lastRefreshFailedAt!.isAfter(lastUpdatedAt!);
  }
}
