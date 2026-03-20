import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/home/presentation/pages/home_page.dart';

class PaperlessNgxApp extends ConsumerWidget {
  const PaperlessNgxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return MaterialApp(
      title: 'Paperless-ngx',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: session.isAuthenticated ? const HomePage() : const LoginPage(),
    );
  }
}
