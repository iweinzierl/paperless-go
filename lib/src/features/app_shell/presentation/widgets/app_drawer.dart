import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/help_feedback_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/recently_opened_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(appDrawerStatisticsProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Text(
                'Paperless-ngx',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            _DrawerDestination(
              icon: Icons.history,
              title: 'Recently opened',
              onTap: () => _openPage(context, const RecentlyOpenedPage()),
            ),
            _DrawerDestination(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => _openPage(context, const SettingsPage()),
            ),
            _DrawerDestination(
              icon: Icons.help_outline,
              title: 'Help & Feedback',
              onTap: () => _openPage(context, const HelpFeedbackPage()),
            ),
            const SizedBox(height: 16),
            _StatisticsPanel(stats: stats),
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

class _StatisticsPanel extends StatelessWidget {
  const _StatisticsPanel({required this.stats});

  final AsyncValue<AppDrawerStatistics> stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: stats.when(
          data: (value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _StatisticRow(label: 'Documents', value: value.documents),
              _StatisticRow(
                label: 'Correspondents',
                value: value.correspondents,
              ),
              _StatisticRow(label: 'Tags', value: value.tags),
              _StatisticRow(
                label: 'Document types',
                value: value.documentTypes,
              ),
            ],
          ),
          error: (error, stackTrace) => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text('Statistics are unavailable right now.'),
            ],
          ),
          loading: () => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  const _StatisticRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
