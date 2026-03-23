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

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _DrawerDestination(
              icon: Icons.history,
              title: l10n.drawerRecentlyOpened,
              onTap: () => _openPage(context, const RecentlyOpenedPage()),
            ),
            _DrawerDestination(
              icon: Icons.settings_outlined,
              title: l10n.drawerSettings,
              onTap: () => _openPage(context, const SettingsPage()),
            ),
            _DrawerDestination(
              icon: Icons.help_outline,
              title: l10n.drawerHelpFeedback,
              onTap: () => _openPage(context, const HelpFeedbackPage()),
            ),
            if (donationConfiguration.isEnabled)
              _DrawerDestination(
                icon: Icons.volunteer_activism_outlined,
                title: l10n.donateTitle,
                onTap: () => _openDonation(context, ref, donationConfiguration),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _ManagementSection(stats: stats),
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

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      title: Align(alignment: Alignment.centerLeft, child: Text(title)),
      trailing: Text(
        count?.toString() ?? '...',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

Future<void> _openDrawerPage(BuildContext context, Widget page) async {
  Navigator.of(context).pop();
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (context) => page));
}
