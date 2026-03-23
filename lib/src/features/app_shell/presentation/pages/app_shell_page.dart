import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/review_queue_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';
import 'package:paperless_ngx_app/src/features/home/presentation/pages/home_page.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedTab = ref.watch(appShellTabProvider);
    final reviewQueueCount = ref.watch(reviewQueueCountProvider);

    return Scaffold(
      body: switch (selectedTab) {
        0 => const DocumentsPage(),
        1 => const HomePage(),
        2 => const ReviewQueuePage(),
        _ => const DocumentsPage(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          ref.read(appShellTabProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.folder_open_outlined),
            label: l10n.navigationDocuments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            label: l10n.navigationRecent,
          ),
          NavigationDestination(
            icon: Badge.count(
              isLabelVisible: reviewQueueCount > 0,
              count: reviewQueueCount,
              child: const Icon(Icons.fact_check_outlined),
            ),
            label: l10n.navigationInbox,
          ),
        ],
      ),
    );
  }
}
