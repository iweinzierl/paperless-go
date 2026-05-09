import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/review_queue_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/scan_document_page.dart';
import 'package:paperless_ngx_app/src/features/home/presentation/pages/home_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/widgets/app_drawer.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key, this.drawerUserCardSubtitleOverride});

  final String? drawerUserCardSubtitleOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedTab = ref.watch(appShellTabProvider);
    final reviewQueueCount = ref.watch(reviewQueueCountProvider);
    final isDrawerMinimized = ref.watch(appDrawerMinimizedProvider);
    final page = switch (selectedTab) {
      0 => const DocumentsPage(),
      1 => const HomePage(),
      2 => const ReviewQueuePage(),
      _ => const DocumentsPage(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (useWideLayoutForSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        )) {
          return Scaffold(
            body: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  width: isDrawerMinimized ? 90 : 320,
                  child: AppDrawer(
                    isPermanent: true,
                    isMinimized: isDrawerMinimized,
                    userCardSubtitleOverride: drawerUserCardSubtitleOverride,
                  ),
                ),
                Expanded(child: page),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _openScanDocument(context),
              child: const Icon(Icons.document_scanner_outlined, size: 24),
            ),
          );
        }

        return Scaffold(
          body: page,
          bottomNavigationBar: _ShellBottomBar(
            selectedIndex: selectedTab,
            reviewQueueCount: reviewQueueCount,
            onSelected: (index) =>
                ref.read(appShellTabProvider.notifier).state = index,
            onScan: () => _openScanDocument(context),
            documentsLabel: l10n.navigationDocuments,
            recentLabel: l10n.navigationRecent,
            inboxLabel: l10n.navigationInbox,
            scanLabel: l10n.scanDocumentAction,
          ),
        );
      },
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
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.selectedIndex,
    required this.reviewQueueCount,
    required this.onSelected,
    required this.onScan,
    required this.documentsLabel,
    required this.recentLabel,
    required this.inboxLabel,
    required this.scanLabel,
  });

  final int selectedIndex;
  final int reviewQueueCount;
  final ValueChanged<int> onSelected;
  final VoidCallback onScan;
  final String documentsLabel;
  final String recentLabel;
  final String inboxLabel;
  final String scanLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: BottomAppBar(
        height: 74,
        padding: EdgeInsets.zero,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: _ShellNavItem(
                    icon: Icons.folder_outlined,
                    label: documentsLabel,
                    selected: selectedIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                ),
                Expanded(
                  child: _ShellNavItem(
                    icon: Icons.schedule_outlined,
                    label: recentLabel,
                    selected: selectedIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                ),
                Expanded(
                  child: _ShellNavItem(
                    icon: Icons.inbox_outlined,
                    label: inboxLabel,
                    selected: selectedIndex == 2,
                    badgeCount: reviewQueueCount,
                    onTap: () => onSelected(2),
                  ),
                ),
                Expanded(
                  child: _ShellNavItem(
                    icon: Icons.document_scanner_outlined,
                    label: scanLabel,
                    selected: false,
                    onTap: onScan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final background = selected
        ? theme.colorScheme.primaryContainer
        : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge.count(
              isLabelVisible: badgeCount > 0,
              count: badgeCount,
              child: Icon(icon, color: foreground, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
