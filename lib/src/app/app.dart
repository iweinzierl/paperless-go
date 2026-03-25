import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_security_providers.dart';
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

class _PaperlessNgxAppState extends ConsumerState<PaperlessNgxApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ProviderSubscription<PaperlessAuthSession> _authSubscription;
  late final ProviderSubscription<AppBehaviorSettings> _behaviorSubscription;
  late final ProviderSubscription<IncomingPdfState> _incomingPdfSubscription;
  bool _isHandlingIncomingPdf = false;
  bool _isAppLocked = false;
  bool _isUnlockingApp = false;
  String? _unlockErrorMessage;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final session = ref.read(authSessionProvider);
    final behaviorSettings = ref.read(appBehaviorSettingsProvider);
    _isAppLocked =
        session.isAuthenticated && behaviorSettings.biometricLockEnabled;

    _authSubscription = ref.listenManual<PaperlessAuthSession>(
      authSessionProvider,
      (previous, next) {
        if (!next.isAuthenticated) {
          _backgroundedAt = null;
          _clearLockState();
        } else if (previous?.isAuthenticated != true) {
          _scheduleBiometricPromptIfNeeded();
        }

        _scheduleIncomingPdfHandling();
      },
    );
    _behaviorSubscription = ref.listenManual<AppBehaviorSettings>(
      appBehaviorSettingsProvider,
      (previous, next) {
        final session = ref.read(authSessionProvider);
        if (!session.isAuthenticated || !next.biometricLockEnabled) {
          _backgroundedAt = null;
          _clearLockState();
        }
      },
    );
    _incomingPdfSubscription = ref.listenManual<IncomingPdfState>(
      incomingPdfControllerProvider,
      (previous, next) => _scheduleIncomingPdfHandling(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleIncomingPdfHandling();
      if (_isAppLocked) {
        unawaited(_unlockApp());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.close();
    _behaviorSubscription.close();
    _incomingPdfSubscription.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isUnlockingApp) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _markAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        unawaited(_lockAndUnlockIfNeeded());
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _scheduleIncomingPdfHandling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_handleIncomingPdfIfPossible());
    });
  }

  void _scheduleBiometricPromptIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_showBiometricPromptIfNeeded());
    });
  }

  Future<void> _handleIncomingPdfIfPossible() async {
    if (_isHandlingIncomingPdf || _isAppLocked || _isUnlockingApp) {
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

      final navigatorContext = _navigatorKey.currentContext;
      if (!mounted || navigatorContext == null || !navigatorContext.mounted) {
        return;
      }

      final l10n = AppLocalizations.of(navigatorContext);
      final messenger = ScaffoldMessenger.maybeOf(navigatorContext);
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

  void _markAppBackgrounded() {
    final session = ref.read(authSessionProvider);
    final behaviorSettings = ref.read(appBehaviorSettingsProvider);
    if (!session.isAuthenticated || !behaviorSettings.biometricLockEnabled) {
      return;
    }

    _backgroundedAt ??= DateTime.now();
  }

  Future<void> _lockAndUnlockIfNeeded() async {
    final session = ref.read(authSessionProvider);
    final behaviorSettings = ref.read(appBehaviorSettingsProvider);
    if (!session.isAuthenticated || !behaviorSettings.biometricLockEnabled) {
      _backgroundedAt = null;
      return;
    }

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) {
      return;
    }

    final elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed < behaviorSettings.appLockTimeout.duration) {
      return;
    }

    if (mounted) {
      setState(() {
        _isAppLocked = true;
        _unlockErrorMessage = null;
      });
    }
    await _unlockApp();
  }

  Future<void> _unlockApp() async {
    final session = ref.read(authSessionProvider);
    final behaviorSettings = ref.read(appBehaviorSettingsProvider);
    if (!session.isAuthenticated || !behaviorSettings.biometricLockEnabled) {
      _clearLockState();
      return;
    }
    if (_isUnlockingApp) {
      return;
    }

    final localizationContext = _navigatorKey.currentContext ?? context;
    final l10n = AppLocalizations.of(localizationContext);
    if (l10n == null) {
      return;
    }

    setState(() {
      _isAppLocked = true;
      _isUnlockingApp = true;
      _unlockErrorMessage = null;
    });

    final didAuthenticate = await ref
        .read(biometricAuthServiceProvider)
        .authenticate(localizedReason: l10n.biometricUnlockReason);
    if (!mounted) {
      return;
    }

    setState(() {
      _isUnlockingApp = false;
      _isAppLocked = !didAuthenticate;
      _unlockErrorMessage = didAuthenticate ? null : l10n.biometricUnlockFailed;
    });
  }

  Future<void> _showBiometricPromptIfNeeded() async {
    final session = ref.read(authSessionProvider);
    final behaviorSettings = ref.read(appBehaviorSettingsProvider);
    if (!session.isAuthenticated || behaviorSettings.biometricLockEnabled) {
      return;
    }

    final preferences = ref.read(appBehaviorPreferencesProvider);
    if (preferences.hasShownBiometricPrompt()) {
      return;
    }

    final biometricAuthService = ref.read(biometricAuthServiceProvider);
    final isAvailable = await biometricAuthService.isAvailable();
    if (!mounted || !isAvailable) {
      return;
    }

    final promptContext = _navigatorKey.currentContext;
    if (promptContext == null || !promptContext.mounted) {
      return;
    }

    final l10n = AppLocalizations.of(promptContext);
    if (l10n == null) {
      return;
    }

    await preferences.markBiometricPromptShown();
    if (!mounted) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      return;
    }

    final shouldEnable = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.biometricPromptTitle),
          content: Text(l10n.biometricPromptMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.biometricPromptNotNowAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.biometricPromptEnableAction),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldEnable != true) {
      return;
    }

    final didAuthenticate = await biometricAuthService.authenticate(
      localizedReason: l10n.biometricEnableReason,
    );
    if (!mounted) {
      return;
    }

    final feedbackContext = _navigatorKey.currentContext;
    final messenger = feedbackContext == null || !feedbackContext.mounted
        ? null
        : ScaffoldMessenger.maybeOf(feedbackContext);
    if (!didAuthenticate) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.biometricLockEnableFailed)));
      return;
    }

    ref
        .read(appBehaviorSettingsProvider.notifier)
        .setBiometricLockEnabled(true);
  }

  void _clearLockState() {
    if (!mounted) {
      _isAppLocked = false;
      _isUnlockingApp = false;
      _unlockErrorMessage = null;
      return;
    }

    setState(() {
      _isAppLocked = false;
      _isUnlockingApp = false;
      _unlockErrorMessage = null;
    });
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
      builder: (context, child) {
        final showAppLock =
            session.isAuthenticated &&
            behaviorSettings.biometricLockEnabled &&
            (_isAppLocked || _isUnlockingApp);

        return Stack(
          children: [
            if (child != null) child,
            if (showAppLock)
              Positioned.fill(
                child: _AppLockOverlay(
                  isUnlocking: _isUnlockingApp,
                  errorMessage: _unlockErrorMessage,
                  onUnlockPressed: _unlockApp,
                  onSignOutPressed: () =>
                      ref.read(authSessionProvider.notifier).signOut(),
                ),
              ),
          ],
        );
      },
      home: session.isAuthenticated ? const AppShellPage() : const LoginPage(),
    );
  }
}

class _AppLockOverlay extends StatelessWidget {
  const _AppLockOverlay({
    required this.isUnlocking,
    required this.errorMessage,
    required this.onUnlockPressed,
    required this.onSignOutPressed,
  });

  final bool isUnlocking;
  final String? errorMessage;
  final Future<void> Function() onUnlockPressed;
  final VoidCallback onSignOutPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.biometricUnlockTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    errorMessage ?? l10n.biometricUnlockSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isUnlocking ? null : () => onUnlockPressed(),
                      icon: isUnlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(
                        isUnlocking
                            ? l10n.biometricUnlockingStatus
                            : l10n.biometricUnlockAction,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isUnlocking ? null : onSignOutPressed,
                    child: Text(l10n.signOutAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
