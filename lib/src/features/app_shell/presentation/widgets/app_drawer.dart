import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/help_feedback_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/manage_filter_options_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/recently_opened_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.isPermanent = false,
    this.isMinimized = false,
  });

  final bool isPermanent;
  final bool isMinimized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final stats = ref.watch(appDrawerStatisticsProvider);
    final donationConfiguration = ref.watch(donationConfigurationProvider);
    final session = ref.watch(authSessionProvider);
    final displayName = (session.displayName?.trim().isNotEmpty ?? false)
        ? session.displayName!.trim()
        : session.username;
    final serverHost = Uri.tryParse(session.serverUrl)?.host;
    final initials = _buildInitials(displayName);
    final reviewQueueCount = ref.watch(reviewQueueCountProvider);
    final selectedTab = ref.watch(appShellTabProvider);
    final primaryDestinations = <_DrawerAction>[
      _DrawerAction(
        icon: Icons.history,
        title: l10n.drawerRecentlyOpened,
        onTap: () => _openPage(context, const RecentlyOpenedPage()),
      ),
      _DrawerAction(
        icon: Icons.settings_outlined,
        title: l10n.drawerSettings,
        onTap: () => _openPage(context, const SettingsPage()),
      ),
      _DrawerAction(
        icon: Icons.help_outline,
        title: l10n.drawerHelpFeedback,
        onTap: () => _openPage(context, const HelpFeedbackPage()),
      ),
      if (donationConfiguration.isEnabled &&
          defaultTargetPlatform != TargetPlatform.iOS)
        _DrawerAction(
          icon: Icons.volunteer_activism_outlined,
          title: l10n.donateTitle,
          onTap: () => _openDonation(context, ref, donationConfiguration),
        ),
    ];

    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isMinimized ? 12 : 18,
            18,
            isMinimized ? 12 : 18,
            14,
          ),
          children: [
            if (isMinimized)
              Column(
                children: [
                  if (isPermanent) ...[
                    IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: l10n.drawerMainMenu,
                      onPressed: () =>
                          ref.read(appDrawerMinimizedProvider.notifier).state =
                              false,
                    ),
                  ],
                ],
              )
            else
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'android/app/src/main/ic_launcher-playstore.png',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  if (isPermanent)
                    IconButton(
                      icon: const Icon(Icons.menu_open),
                      onPressed: () =>
                          ref.read(appDrawerMinimizedProvider.notifier).state =
                              true,
                    ),
                ],
              ),
            const SizedBox(height: 18),
            if (!isMinimized) ...[
              _DrawerSectionLabel(label: l10n.drawerMainMenu),
              const SizedBox(height: 10),
            ],
            if (isPermanent) ...[
              _DrawerActionTile(
                action: _DrawerAction(
                  icon: Icons.folder_outlined,
                  title: l10n.navigationDocuments,
                  onTap: () => ref.read(appShellTabProvider.notifier).state = 0,
                ),
                highlighted: selectedTab == 0,
                isMinimized: isMinimized,
              ),
              const SizedBox(height: 4),
              _DrawerActionTile(
                action: _DrawerAction(
                  icon: Icons.schedule_outlined,
                  title: l10n.navigationRecent,
                  onTap: () => ref.read(appShellTabProvider.notifier).state = 1,
                ),
                highlighted: selectedTab == 1,
                isMinimized: isMinimized,
              ),
              const SizedBox(height: 4),
              _DrawerActionTile(
                action: _DrawerAction(
                  icon: Icons.inbox_outlined,
                  title: l10n.navigationInbox,
                  onTap: () => ref.read(appShellTabProvider.notifier).state = 2,
                ),
                badgeCount: reviewQueueCount,
                highlighted: selectedTab == 2,
                isMinimized: isMinimized,
              ),
              const SizedBox(height: 14),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 14),
              if (!isMinimized) ...[
                _DrawerSectionLabel(label: l10n.drawerSettings.toUpperCase()),
                const SizedBox(height: 10),
              ],
            ],
            for (
              var index = 0;
              index < primaryDestinations.length;
              index++
            ) ...[
              _DrawerActionTile(
                action: primaryDestinations[index],
                highlighted: false,
                isMinimized: isMinimized,
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 14),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            if (!isMinimized) ...[
              _DrawerSectionLabel(label: l10n.drawerCategories),
              const SizedBox(height: 8),
            ],
            _ManagementSection(
              stats: stats,
              onOpenPage: _openPage,
              isMinimized: isMinimized,
            ),
            const SizedBox(height: 16),
            _DrawerUserCard(
              initials: initials,
              title: displayName,
              subtitle: serverHost == null || serverHost.isEmpty
                  ? session.serverUrl
                  : 'Server: $serverHost',
              isMinimized: isMinimized,
              onTap: () => _openPage(context, const SettingsPage()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    if (!isPermanent) {
      Navigator.of(context).pop();
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => page));
  }

  Future<void> _openDonation(
    BuildContext context,
    WidgetRef ref,
    DonationConfiguration donationConfiguration,
  ) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final launcher = ref.read(helpLinkLauncherProvider);
    if (!isPermanent) {
      Navigator.of(context).pop();
    }

    await showDonateDialog(rootContext, launcher, donationConfiguration);
  }
}

class _DrawerAction {
  const _DrawerAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.action,
    required this.highlighted,
    this.badgeCount = 0,
    this.isMinimized = false,
  });

  final _DrawerAction action;
  final bool highlighted;
  final int badgeCount;
  final bool isMinimized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = highlighted
        ? theme.colorScheme.primary
        : Colors.transparent;
    final foregroundColor = highlighted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final tile = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisAlignment: isMinimized
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Badge.count(
                isLabelVisible: badgeCount > 0,
                count: badgeCount,
                child: Icon(action.icon, color: foregroundColor, size: 22),
              ),
              if (!isMinimized) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: highlighted
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isMinimized) {
      return Tooltip(
        message: action.title,
        waitDuration: const Duration(milliseconds: 500),
        child: tile,
      );
    }

    return tile;
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({
    required this.stats,
    required this.onOpenPage,
    this.isMinimized = false,
  });

  final AsyncValue<AppDrawerStatistics> stats;
  final Future<void> Function(BuildContext, Widget) onOpenPage;
  final bool isMinimized;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final correspondentsCount = stats.maybeWhen(
      data: (value) => value.correspondents,
      orElse: () => null,
    );
    final documentTypesCount = stats.maybeWhen(
      data: (value) => value.documentTypes,
      orElse: () => null,
    );
    final tagsCount = stats.maybeWhen(
      data: (value) => value.tags,
      orElse: () => null,
    );

    return Column(
      children: [
        _ManagementDestination(
          icon: Icons.manage_search_outlined,
          title: l10n.drawerCorrespondents,
          count: correspondentsCount,
          onTap: () => onOpenPage(
            context,
            const ManageFilterOptionsPage(
              type: ManageFilterOptionType.correspondents,
            ),
          ),
          isMinimized: isMinimized,
        ),
        _ManagementDestination(
          icon: Icons.category_outlined,
          title: l10n.drawerDocumentTypes,
          count: documentTypesCount,
          onTap: () => onOpenPage(
            context,
            const ManageFilterOptionsPage(
              type: ManageFilterOptionType.documentTypes,
            ),
          ),
          isMinimized: isMinimized,
        ),
        _ManagementDestination(
          icon: Icons.sell_outlined,
          title: l10n.drawerTags,
          count: tagsCount,
          onTap: () => onOpenPage(
            context,
            const ManageFilterOptionsPage(type: ManageFilterOptionType.tags),
          ),
          isMinimized: isMinimized,
        ),
      ],
    );
  }
}

class _ManagementDestination extends StatelessWidget {
  const _ManagementDestination({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
    this.isMinimized = false,
  });

  final IconData icon;
  final String title;
  final int? count;
  final VoidCallback onTap;
  final bool isMinimized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: isMinimized
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 21),
            if (!isMinimized) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _CountPill(label: count?.toString() ?? '...'),
            ],
          ],
        ),
      ),
    );

    if (isMinimized) {
      return Tooltip(
        message: title,
        waitDuration: const Duration(milliseconds: 500),
        child: tile,
      );
    }

    return tile;
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DrawerUserCard extends StatelessWidget {
  const _DrawerUserCard({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isMinimized = false,
  });

  final String initials;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isMinimized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = Material(
      color: isMinimized
          ? Colors.transparent
          : theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(isMinimized ? 999 : 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(isMinimized ? 999 : 20),
        onTap: onTap,
        child: Padding(
          padding: isMinimized
              ? const EdgeInsets.all(8)
              : const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: isMinimized
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(
                      initials,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3CCB7F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surfaceContainer,
                          width: 2,
                        ),
                      ),
                      child: const SizedBox(width: 12, height: 12),
                    ),
                  ),
                ],
              ),
              if (!isMinimized) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isMinimized) {
      return Tooltip(
        message: '$title\n$subtitle',
        waitDuration: const Duration(milliseconds: 500),
        child: tile,
      );
    }

    return tile;
  }
}

String _buildInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'PG';
  }
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
