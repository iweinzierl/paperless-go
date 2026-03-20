import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';
import 'package:paperless_ngx_app/src/features/home/presentation/pages/home_page.dart';

class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(appShellTabProvider);

    return Scaffold(
      body: switch (selectedTab) {
        1 => const DocumentsPage(),
        _ => const HomePage(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          ref.read(appShellTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            label: 'Documents',
          ),
        ],
      ),
    );
  }
}
