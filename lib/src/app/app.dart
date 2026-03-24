import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/scan_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/incoming_pdf_controller.dart';

class PaperlessNgxApp extends ConsumerStatefulWidget {
  const PaperlessNgxApp({super.key});

  @override
  ConsumerState<PaperlessNgxApp> createState() => _PaperlessNgxAppState();
}

class _PaperlessNgxAppState extends ConsumerState<PaperlessNgxApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ProviderSubscription<PaperlessAuthSession> _authSubscription;
  late final ProviderSubscription<IncomingPdfState> _incomingPdfSubscription;
  bool _isHandlingIncomingPdf = false;

  @override
  void initState() {
    super.initState();

    _authSubscription = ref.listenManual<PaperlessAuthSession>(
      authSessionProvider,
      (previous, next) => _scheduleIncomingPdfHandling(),
    );
    _incomingPdfSubscription = ref.listenManual<IncomingPdfState>(
      incomingPdfControllerProvider,
      (previous, next) => _scheduleIncomingPdfHandling(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleIncomingPdfHandling();
    });
  }

  @override
  void dispose() {
    _authSubscription.close();
    _incomingPdfSubscription.close();
    super.dispose();
  }

  void _scheduleIncomingPdfHandling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_handleIncomingPdfIfPossible());
    });
  }

  Future<void> _handleIncomingPdfIfPossible() async {
    if (_isHandlingIncomingPdf) {
      return;
    }

    final session = ref.read(authSessionProvider);
    final incomingPdfState = ref.read(incomingPdfControllerProvider);
    if (!session.isAuthenticated || incomingPdfState.pendingPdfPath == null) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final pendingPdfPath = ref
        .read(incomingPdfControllerProvider.notifier)
        .consumePendingPdfPath();
    if (pendingPdfPath == null) {
      return;
    }

    _isHandlingIncomingPdf = true;
    try {
      final taskId = await navigator.push<String>(
        MaterialPageRoute<String>(
          builder: (context) =>
              ScanDocumentPage(initialImportedDocumentPath: pendingPdfPath),
        ),
      );

      if (!mounted || taskId == null || taskId.isEmpty) {
        return;
      }

      final context = _navigatorKey.currentContext;
      if (!mounted || context == null) {
        return;
      }

      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (l10n == null || messenger == null) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.scanDocumentQueued)));
    } finally {
      _isHandlingIncomingPdf = false;
      if (mounted) {
        _scheduleIncomingPdfHandling();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final session = ref.watch(authSessionProvider);
    final behaviorSettings = ref.watch(appBehaviorSettingsProvider);
    ref.watch(incomingPdfControllerProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
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
