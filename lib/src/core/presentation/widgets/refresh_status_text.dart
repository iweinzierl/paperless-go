import 'package:flutter/material.dart';

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

    return Text(
      _buildLabel(),
      style: theme.textTheme.bodySmall?.copyWith(
        color: hasRefreshFailure
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _buildLabel() {
    if (_hasRefreshFailure()) {
      return 'Refresh failed at ${_formatTime(lastRefreshFailedAt!)}';
    }

    if (isRefreshing && lastUpdatedAt == null) {
      return 'Refreshing...';
    }

    if (lastUpdatedAt == null) {
      return 'Waiting for first sync';
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdatedAt!);
    final formattedTime = _formatTime(lastUpdatedAt!);

    if (isRefreshing) {
      return 'Refreshing... last updated $formattedTime';
    }

    if (difference < const Duration(minutes: 1)) {
      return 'Updated just now';
    }

    if (difference < const Duration(hours: 1)) {
      return 'Updated ${difference.inMinutes} min ago';
    }

    return 'Updated $formattedTime';
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

  String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
