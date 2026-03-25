import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/help_feedback_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/manage_filter_options_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/recently_opened_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appDrawerStatisticsProvider);
    final donationConfiguration = ref.watch(donationConfigurationProvider);
    final l10n = context.l10n;
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

    return NavigationDrawer(
      onDestinationSelected: (index) => primaryDestinations[index].onTap(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
          child: Text(
            l10n.appTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (final destination in primaryDestinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            label: Text(destination.title),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 12, 28, 8),
          child: Divider(),
        ),
        _ManagementSection(stats: stats),
      ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Column(
        children: [
          _ManagementDestination(
            icon: Icons.people_outline,
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
            icon: Icons.description_outlined,
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
            icon: Icons.label_outline,
            title: l10n.drawerTags,
            count: tagsCount,
            onTap: () => _openDrawerPage(
              context,
              const ManageFilterOptionsPage(type: ManageFilterOptionType.tags),
            ),
          ),
        ],
      ),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        count?.toString() ?? '...',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

Future<void> _openDrawerPage(BuildContext context, Widget page) async {
  Navigator.of(context).pop();
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (context) => page));
}
