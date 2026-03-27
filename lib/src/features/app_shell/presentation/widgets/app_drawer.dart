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
  const AppDrawer({super.key});

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
      if (donationConfiguration.isEnabled)
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          children: [
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
              ],
            ),
            const SizedBox(height: 18),
            _DrawerSectionLabel(label: l10n.drawerMainMenu),
            const SizedBox(height: 10),
            for (
              var index = 0;
              index < primaryDestinations.length;
              index++
            ) ...[
              _DrawerActionTile(
                action: primaryDestinations[index],
                highlighted: false,
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 14),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            _DrawerSectionLabel(label: l10n.drawerCategories),
            const SizedBox(height: 8),
            _ManagementSection(stats: stats),
            const SizedBox(height: 16),
            _DrawerUserCard(
              initials: initials,
              title: displayName,
              subtitle: serverHost == null || serverHost.isEmpty
                  ? session.serverUrl
                  : 'Server: $serverHost',
              onTap: () => _openPage(context, const SettingsPage()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    Navigator.of(context).pop();
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
    Navigator.of(context).pop();

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
  const _DrawerActionTile({required this.action, required this.highlighted});

  final _DrawerAction action;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = highlighted
        ? theme.colorScheme.primary
        : Colors.transparent;
    final foregroundColor = highlighted
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(action.icon, color: foregroundColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  action.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({required this.stats});

  final AsyncValue<AppDrawerStatistics> stats;

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
          onTap: () => _openDrawerPage(
            context,
            const ManageFilterOptionsPage(
              type: ManageFilterOptionType.correspondents,
            ),
          ),
        ),
        _ManagementDestination(
          icon: Icons.category_outlined,
          title: l10n.drawerDocumentTypes,
          count: documentTypesCount,
          onTap: () => _openDrawerPage(
            context,
            const ManageFilterOptionsPage(
              type: ManageFilterOptionType.documentTypes,
            ),
          ),
        ),
        _ManagementDestination(
          icon: Icons.sell_outlined,
          title: l10n.drawerTags,
          count: tagsCount,
          onTap: () => _openDrawerPage(
            context,
            const ManageFilterOptionsPage(type: ManageFilterOptionType.tags),
          ),
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
  });

  final IconData icon;
  final String title;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 21),
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
        ),
      ),
    );
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
  });

  final String initials;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
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
          ),
        ),
      ),
    );
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

Future<void> _openDrawerPage(BuildContext context, Widget page) async {
  Navigator.of(context).pop();
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (context) => page));
}
