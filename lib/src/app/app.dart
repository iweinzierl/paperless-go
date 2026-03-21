import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';

class PaperlessNgxApp extends ConsumerWidget {
  const PaperlessNgxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final behaviorSettings = ref.watch(appBehaviorSettingsProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: behaviorSettings.appLanguage.locale,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: behaviorSettings.themeMode.materialThemeMode,
      home: session.isAuthenticated ? const AppShellPage() : const LoginPage(),
    );
  }
}
