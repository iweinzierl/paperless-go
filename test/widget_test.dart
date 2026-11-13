// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/app/app.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/app_shell/data/device/biometric_auth_service.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_security_providers.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/incoming_pdf_controller.dart';

void main() {
  const fakeRecentDocument = PaperlessDocument(
    id: 1,
    title: 'Quarterly tax summary.pdf',
    created: '2026-03-20',
    added: '2026-03-20T12:00:00Z',
    pageCount: 4,
  );

  const fakeDocumentsPage = PaperlessDocumentPage(
    count: 1,
    results: [fakeRecentDocument],
  );

  const fakeTodoDocument = PaperlessDocument(
    id: 2,
    title: 'Insurance claim.pdf',
    created: '2026-03-19',
    added: '2026-03-19T08:30:00Z',
    pageCount: 2,
  );

  const fakeOwnedRecentDocument = PaperlessDocument(
    id: 1,
    title: 'Quarterly tax summary.pdf',
    created: '2026-03-20',
    added: '2026-03-20T12:00:00Z',
    pageCount: 4,
    ownerId: 7,
  );

  const fakeSharedEditableDocument = PaperlessDocument(
    id: 3,
    title: 'Shared vendor contract.pdf',
    created: '2026-03-18',
    added: '2026-03-18T09:15:00Z',
    pageCount: 8,
    ownerId: 42,
    permissions: PaperlessObjectPermissions(
      view: PaperlessPermissionAssignments(userIds: <int>[], groupIds: <int>[]),
      change: PaperlessPermissionAssignments(
        userIds: <int>[7],
        groupIds: <int>[],
      ),
    ),
  );

  const fullAccessCapabilities = PaperlessUserCapabilities(
    userId: 7,
    groupIds: <int>[],
    permissionCodenames: <String>{'change_document', 'delete_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const changeOnlyCapabilities = PaperlessUserCapabilities(
    userId: 7,
    groupIds: <int>[],
    permissionCodenames: <String>{'change_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const fakeFilterOptions = [PaperlessFilterOption(id: 1, name: 'Inbox')];
  const fakeDrawerStatistics = AppDrawerStatistics(
    correspondents: 12,
    tags: 34,
    documentTypes: 7,
  );

  const fakeSession = PaperlessAuthSession(
    serverUrl: 'https://example.com/paperless/',
    username: 'jane.doe',
    password: 'secret',
    authToken: 'token-123',
    displayName: 'Jane Doe',
  );

  final fakeRecentlyOpenedDocument = RecentlyOpenedDocument(
    id: 99,
    title: 'Rent contract.pdf',
    openedAt: DateTime(2026, 3, 20, 9, 45),
    added: '2026-03-18T10:15:00Z',
    pageCount: 6,
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialValues = const <String, Object>{},
    List<Override> overrides = const <Override>[],
    DocumentsRepository? documentsRepository,
  }) async {
    // The default 800x600 test surface triggers the wide layout; these tests
    // exercise the compact phone layout.
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
      appName: 'Paperless Ngx App',
      packageName: 'paperless_ngx_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(initialValues);
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final authTokenStorage = await AuthTokenStorage.load(
      const FlutterSecureStorage(),
      sharedPreferences,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authTokenStorageProvider.overrideWithValue(authTokenStorage),
          incomingPdfControllerProvider.overrideWith(
            _FakeIncomingPdfController.new,
          ),
          incomingPdfPlatformBridgeProvider.overrideWith(
            (ref) => const _FakeIncomingPdfPlatformBridge(),
          ),
          appDrawerStatisticsProvider.overrideWith(
            (ref) async => fakeDrawerStatistics,
          ),
          biometricAuthServiceProvider.overrideWithValue(
            _FakeBiometricAuthService(),
          ),
          documentsRepositoryProvider.overrideWithValue(
            documentsRepository ?? _FakeDocumentsRepository(),
          ),
          ...overrides,
        ],
        child: const PaperlessNgxApp(),
      ),
    );

    await tester.pump();
  }

  Finder settingsScrollable() => find.byType(Scrollable).first;

  // The document detail page embeds a network PDF preview whose loading
  // indicator never settles in tests, so pump a bounded number of frames.
  Future<void> pumpDetailPage(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder addCorrespondentButton() => find.byIcon(Icons.add_rounded).at(0);
  Finder addDocumentTypeButton() => find.byIcon(Icons.add_rounded).at(1);

  Future<void> refreshFromOverflowMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Show menu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh'));
  }

  Override overrideCapabilities(PaperlessUserCapabilities? capabilities) {
    return currentUserCapabilitiesProvider.overrideWith(
      (ref) async => capabilities,
    );
  }

  testWidgets('opens settings page with existing connection values', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        appShellTabProvider.overrideWith((ref) => 1),
        recentUploadsProvider.overrideWith((ref) async => const []),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Connected as Jane Doe'), findsOneWidget);
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('https://example.com/paperless/'), findsWidgets);
    expect(find.text('jane.doe'), findsOneWidget);
    expect(find.text('Save settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Appearance & Behavior'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appearance & Behavior'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('System default'), findsWidgets);
    expect(find.text('Cache thumbnails and previews'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theme mode'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Theme mode'), findsOneWidget);
    expect(find.text('Light'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Cache thumbnails and previews'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todos'), findsNothing);
    expect(find.text('TODO tags'), findsNothing);
    expect(find.text('Select TODO tags'), findsNothing);
  });

  testWidgets('uses saved dark theme mode on startup', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{'app_behavior.theme_mode': 'dark'},
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('shows app lock overlay after resuming past the timeout', (
    WidgetTester tester,
  ) async {
    final biometricAuthService = _FakeBiometricAuthService(
      authenticationResults: <bool>[true, false],
    );

    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
        'app_behavior.biometric_lock_enabled': true,
        'app_behavior.app_lock_timeout': 'immediate',
      },
      overrides: [
        biometricAuthServiceProvider.overrideWithValue(biometricAuthService),
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Unlock Paperless Go'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    expect(
      find.text(
        'Authentication was canceled or failed. Try again to continue.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses saved app language override on startup', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{'app_behavior.app_language': 'fr'},
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.locale, equals(const Locale('fr')));
  });

  testWidgets('prompts to enable biometric lock after first successful login', (
    WidgetTester tester,
  ) async {
    final biometricAuthService = _FakeBiometricAuthService(
      authenticationResults: <bool>[true],
    );

    await pumpApp(
      tester,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(fakeSession),
        ),
        biometricAuthServiceProvider.overrideWithValue(biometricAuthService),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/paperless/',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'jane.doe');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Protect Paperless Go?'), findsOneWidget);
    expect(
      find.text(
        'Enable Face ID or fingerprint now to protect your documents when returning to the app.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Enable now'));
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsWidgets);
    expect(biometricAuthService.authenticateCallCount, equals(1));
  });

  testWidgets('shows the biometric prompt only once after first login', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'app_behavior.biometric_prompt_shown': true,
      },
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(fakeSession),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/paperless/',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'jane.doe');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Protect Paperless Go?'), findsNothing);
    expect(find.text('Documents'), findsWidgets);
  });

  testWidgets('does not prompt after login when biometrics are unavailable', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(fakeSession),
        ),
        biometricAuthServiceProvider.overrideWithValue(
          _FakeBiometricAuthService(isAvailableResult: false),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/paperless/',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'jane.doe');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Protect Paperless Go?'), findsNothing);
    expect(find.text('Documents'), findsWidgets);
  });

  testWidgets('updates theme mode from settings', (WidgetTester tester) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Theme mode'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('shows login page on app start', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Connect to your server'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows documents page when a saved session exists', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsWidgets);
    expect(find.byTooltip('Show menu'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Search by title'), findsOneWidget);
    expect(find.text('Quarterly tax summary.pdf'), findsWidgets);
  });

  testWidgets('opens the scan document flow from the recent page', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recent').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan document'));
    await tester.pumpAndSettle();

    expect(find.text('Start a new scan'), findsOneWidget);
    expect(find.text('Upload scan'), findsNothing);
  });

  testWidgets('shows snackbar after manual recent refresh', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recent').last);
    await tester.pumpAndSettle();

    await refreshFromOverflowMenu(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Home updated.'), findsOneWidget);
  });

  testWidgets('opens document details from recent uploads on tap', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        documentDetailProvider(
          fakeRecentDocument.id,
        ).overrideWith((ref) async => fakeRecentDocument),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quarterly tax summary.pdf').first);
    await pumpDetailPage(tester);

    expect(find.text('Quarterly tax summary.pdf'), findsWidgets);
    expect(find.text('Open document'), findsOneWidget);
    expect(find.text('Edit metadata'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu').first);
    await pumpDetailPage(tester);

    expect(find.text('Open original'), findsOneWidget);
  });

  testWidgets('opens metadata editor from document details', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        overrideCapabilities(fullAccessCapabilities),
        documentDetailProvider(
          fakeRecentDocument.id,
        ).overrideWith((ref) async => fakeOwnedRecentDocument),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quarterly tax summary.pdf').first);
    await pumpDetailPage(tester);

    await tester.tap(find.text('Edit metadata'));
    await pumpDetailPage(tester);

    expect(find.text('Edit metadata'), findsWidgets);
    expect(find.text('TITLE'), findsOneWidget);
    expect(find.text('CREATED DATE'), findsOneWidget);
    expect(find.text('CORRESPONDENT'), findsOneWidget);
    expect(find.text('DOCUMENT TYPE'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
  });

  testWidgets('creates correspondents and document types inline', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDocumentsRepository();

    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      documentsRepository: repository,
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        overrideCapabilities(fullAccessCapabilities),
        documentDetailProvider(
          fakeRecentDocument.id,
        ).overrideWith((ref) async => fakeOwnedRecentDocument),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quarterly tax summary.pdf').first);
    await pumpDetailPage(tester);

    await tester.tap(find.text('Edit metadata'));
    await pumpDetailPage(tester);

    expect(find.text('CORRESPONDENT'), findsOneWidget);
    expect(find.text('DOCUMENT TYPE'), findsOneWidget);

    await tester.tap(addCorrespondentButton());
    await pumpDetailPage(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Acme Corp',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await pumpDetailPage(tester);

    await tester.tap(addDocumentTypeButton());
    await pumpDetailPage(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Invoice',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await pumpDetailPage(tester);

    expect(repository.createdCorrespondentNames, ['Acme Corp']);
    expect(repository.createdDocumentTypeNames, ['Invoice']);
    expect(repository.createdTagNames, isEmpty);
    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
  });

  testWidgets('disables save while a new correspondent is being created', (
    WidgetTester tester,
  ) async {
    final repository = _DelayedFakeDocumentsRepository();

    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      documentsRepository: repository,
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        overrideCapabilities(fullAccessCapabilities),
        documentDetailProvider(
          fakeRecentDocument.id,
        ).overrideWith((ref) async => fakeOwnedRecentDocument),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quarterly tax summary.pdf').first);
    await pumpDetailPage(tester);

    await tester.tap(find.text('Edit metadata'));
    await pumpDetailPage(tester);

    await tester.tap(addCorrespondentButton());
    await pumpDetailPage(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Acme Corp',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    final saveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(saveButton.onPressed, isNull);

    repository.completeCorrespondentCreation();
    await pumpDetailPage(tester);

    final enabledSaveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Save'),
    );
    expect(enabledSaveButton.onPressed, isNotNull);
    expect(repository.createdCorrespondentNames, ['Acme Corp']);
  });

  testWidgets('navigates to documents page from bottom navigation', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents').last);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show menu'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('1 document'), findsOneWidget);
    expect(find.text('Search by title'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(find.text('Sort by'), findsNothing);
    expect(find.text('Tag'), findsNothing);
  });

  testWidgets('reloads documents from the overflow refresh action', (
    WidgetTester tester,
  ) async {
    var documentsPageLoads = 0;

    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async {
          documentsPageLoads++;
          return fakeDocumentsPage;
        }),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Documents').last);
    await tester.pumpAndSettle();

    final loadsBeforeRefresh = documentsPageLoads;
    await refreshFromOverflowMenu(tester);
    await tester.pumpAndSettle();

    expect(documentsPageLoads, loadsBeforeRefresh + 1);
    expect(find.text('Quarterly tax summary.pdf'), findsWidgets);
  });

  testWidgets('opens dedicated filters page from documents page', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filters & Sort by'), findsOneWidget);
    expect(find.text('SORT BY'), findsOneWidget);
    expect(find.text('FILTERS'), findsOneWidget);
    expect(find.text('Tag'), findsOneWidget);
    expect(find.text('Correspondent'), findsOneWidget);
    expect(find.text('Document type'), findsOneWidget);
    expect(find.text('Created from'), findsOneWidget);
    expect(find.text('Created to'), findsOneWidget);
    expect(find.text('Apply filters'), findsOneWidget);
    expect(find.text('Created date'), findsOneWidget);
    expect(find.text('newest first'), findsOneWidget);
  });

  testWidgets('hides delete action without delete capability', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith(
          (ref) async => [fakeSharedEditableDocument],
        ),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        overrideCapabilities(changeOnlyCapabilities),
        documentDetailProvider(
          fakeSharedEditableDocument.id,
        ).overrideWith((ref) async => fakeSharedEditableDocument),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recent').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shared vendor contract.pdf').first);
    await pumpDetailPage(tester);

    await tester.tap(find.byTooltip('Show menu').first);
    await pumpDetailPage(tester);

    expect(find.text('Open original'), findsOneWidget);
    expect(find.text('Delete document'), findsNothing);
  });

  testWidgets('allows shared editors to edit metadata', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith(
          (ref) async => [fakeSharedEditableDocument],
        ),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        overrideCapabilities(fullAccessCapabilities),
        documentDetailProvider(
          fakeSharedEditableDocument.id,
        ).overrideWith((ref) async => fakeSharedEditableDocument),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recent').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shared vendor contract.pdf').first);
    await pumpDetailPage(tester);

    await tester.tap(find.text('Edit metadata'));
    await pumpDetailPage(tester);

    expect(find.text('TITLE'), findsOneWidget);
  });

  testWidgets('shows tagged review documents on the Inbox tab', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        documentDetailProvider(
          fakeTodoDocument.id,
        ).overrideWith((ref) async => fakeTodoDocument),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inbox').last);
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Insurance claim.pdf'), findsWidgets);
  });

  testWidgets('shows empty review queue when inbox is empty', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => const []),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inbox').last);
    await tester.pumpAndSettle();

    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Nothing to review'), findsOneWidget);
    expect(
      find.text(
        'Documents currently in your inbox appear here for manual verification.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows validation errors for empty login form', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter your paperless-ngx server URL.'), findsOneWidget);
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('shows the token field after switching to API token login', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Username & password'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<PaperlessAuthMethod>>(
            find.byType(SegmentedButton<PaperlessAuthMethod>),
          )
          .selected,
      {PaperlessAuthMethod.password},
    );
    final segmentedButtonShape = Theme.of(
      tester.element(find.byType(SegmentedButton<PaperlessAuthMethod>)),
    ).segmentedButtonTheme.style?.shape?.resolve(<WidgetState>{});
    expect(
      segmentedButtonShape,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('API token').first);
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsNothing);
    expect(find.text('Password'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(TextFormField, 'Paste your API token'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Find your token in paperless-ngx under "My Profile" > "API Auth Token".',
      ),
      findsOneWidget,
    );

    final tokenField = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).at(1),
        matching: find.byType(TextField),
      ),
    );
    expect(tokenField.obscureText, isTrue);
    expect(find.byIcon(Icons.key_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('shows the MFA code field only for password login', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    const mfaHelp =
        'The one-time code from your authenticator app. Only needed if MFA is enabled for your account.';
    expect(find.text('MFA code (optional)'), findsOneWidget);
    expect(find.text(mfaHelp), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    final mfaField = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).at(3),
        matching: find.byType(TextField),
      ),
    );
    expect(mfaField.keyboardType, TextInputType.number);
    expect(mfaField.obscureText, isFalse);

    await tester.tap(find.text('API token').first);
    await tester.pumpAndSettle();

    expect(find.text('MFA code (optional)'), findsNothing);
    expect(find.text(mfaHelp), findsNothing);
  });

  testWidgets('sends the MFA code and clears the field after login', (
    WidgetTester tester,
  ) async {
    final authRepository = _FakeAuthRepository(
      fakeSession,
      failure: const AuthFailure.serverMessage('Invalid MFA code'),
    );

    await pumpApp(
      tester,
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://example.com/paperless/',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'jane.doe');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret');
    await tester.enterText(find.byType(TextFormField).at(3), '123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Login'));
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(authRepository.receivedCode, '123456');
    expect(find.text('Invalid MFA code'), findsOneWidget);
    final mfaField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(3),
    );
    expect(mfaField.controller!.text, isEmpty);
  });

  testWidgets('shows validation errors for empty API token login form', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('API token').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter your paperless-ngx server URL.'), findsOneWidget);
    expect(find.text('Enter your API token.'), findsOneWidget);
    expect(find.text('Enter your username.'), findsNothing);
    expect(find.text('Enter your password.'), findsNothing);
  });

  testWidgets('opens drawer with menu items and statistics', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Recently opened'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help & Feedback'), findsOneWidget);
    expect(find.text('Correspondents'), findsOneWidget);
    expect(find.text('Document types'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows persisted recently opened documents from the drawer', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
        'app_shell.recently_opened_documents': jsonEncode([
          fakeRecentlyOpenedDocument.toJson(),
        ]),
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentDetailProvider(
          fakeRecentlyOpenedDocument.id,
        ).overrideWith((ref) async => fakeRecentDocument),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recently opened'));
    await tester.pumpAndSettle();

    expect(find.text('Rent contract.pdf'), findsOneWidget);
    expect(find.textContaining('Opened 09:45'), findsOneWidget);
  });

  testWidgets('clears recently opened history from the page action', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
        'app_shell.recently_opened_documents': jsonEncode([
          fakeRecentlyOpenedDocument.toJson(),
        ]),
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recently opened'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Recently opened cleared.'), findsOneWidget);
    expect(
      find.text('Documents you open or inspect will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('opens help and feedback page from the drawer', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        helpLinkLauncherProvider.overrideWith((ref) => _FakeHelpLinkLauncher()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Documentation'), findsOneWidget);
    expect(find.text('Report an issue'), findsOneWidget);
    expect(find.text('Copy support summary'), findsOneWidget);
  });

  testWidgets('copies support summary from the help page', (
    WidgetTester tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          return null;
        }

        return null;
      },
    );

    await pumpApp(
      tester,
      initialValues: const <String, Object>{
        'auth.server_url': 'https://example.com/paperless/',
        'auth.username': 'jane.doe',
        'auth.password': 'secret',
        'auth.token': 'token-123',
        'auth.display_name': 'Jane Doe',
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        reviewDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith((ref) async => fakeFilterOptions),
        correspondentOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
        documentTypeOptionsProvider.overrideWith(
          (ref) async => fakeFilterOptions,
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & Feedback'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy support summary'));
    await tester.pumpAndSettle();

    expect(find.text('Support summary copied.'), findsOneWidget);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

class _FakeBiometricAuthService implements BiometricAuthService {
  _FakeBiometricAuthService({
    this.isAvailableResult = true,
    List<bool> authenticationResults = const <bool>[true],
  }) : _authenticationResults = authenticationResults.toList(growable: true);

  final bool isAvailableResult;
  final List<bool> _authenticationResults;
  int authenticateCallCount = 0;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    authenticateCallCount += 1;

    if (_authenticationResults.isEmpty) {
      return true;
    }

    return _authenticationResults.removeAt(0);
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.session, {this.failure}) : super(Dio());

  final PaperlessAuthSession session;
  final AuthFailure? failure;
  String? receivedCode;

  @override
  Future<PaperlessAuthSession> signIn({
    required String serverUrl,
    required String username,
    required String password,
    String? code,
  }) async {
    receivedCode = code;
    if (failure != null) {
      throw failure!;
    }
    return session;
  }
}

class _FakeHelpLinkLauncher implements HelpLinkLauncher {
  @override
  Future<void> open(Uri uri) async {}
}

class _FakeIncomingPdfPlatformBridge implements IncomingPdfPlatformBridge {
  const _FakeIncomingPdfPlatformBridge();

  @override
  Future<String?> consumeInitialPdfPath() async => null;

  @override
  Stream<String> get openedPdfPaths => const Stream<String>.empty();
}

class _FakeIncomingPdfController extends IncomingPdfController {
  @override
  IncomingPdfState build() => const IncomingPdfState();
}

class _FakeDocumentsRepository extends DocumentsRepository {
  _FakeDocumentsRepository()
    : super(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane.doe',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

  final List<PaperlessFilterOption> _tags = <PaperlessFilterOption>[
    const PaperlessFilterOption(id: 1, name: 'Inbox'),
  ];
  final List<PaperlessFilterOption> _correspondents = <PaperlessFilterOption>[
    const PaperlessFilterOption(id: 1, name: 'Existing sender'),
  ];
  final List<PaperlessFilterOption> _documentTypes = <PaperlessFilterOption>[
    const PaperlessFilterOption(id: 1, name: 'Existing type'),
  ];
  final List<String> createdTagNames = <String>[];
  final List<String> createdCorrespondentNames = <String>[];
  final List<String> createdDocumentTypeNames = <String>[];
  int _nextId = 2;

  @override
  Future<List<PaperlessFilterOption>> fetchTagOptions() async {
    return List<PaperlessFilterOption>.unmodifiable(_tags);
  }

  @override
  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() async {
    return List<PaperlessFilterOption>.unmodifiable(_correspondents);
  }

  @override
  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() async {
    return List<PaperlessFilterOption>.unmodifiable(_documentTypes);
  }

  @override
  Future<PaperlessFilterOption> createTag({required String name}) async {
    createdTagNames.add(name);
    final option = PaperlessFilterOption(id: _nextId++, name: name);
    _tags.add(option);
    return option;
  }

  @override
  Future<PaperlessFilterOption> createCorrespondent({
    required String name,
  }) async {
    createdCorrespondentNames.add(name);
    final option = PaperlessFilterOption(id: _nextId++, name: name);
    _correspondents.add(option);
    return option;
  }

  @override
  Future<PaperlessFilterOption> createDocumentType({
    required String name,
  }) async {
    createdDocumentTypeNames.add(name);
    final option = PaperlessFilterOption(id: _nextId++, name: name);
    _documentTypes.add(option);
    return option;
  }

  @override
  Widget? buildDocumentThumbnailWidget(PaperlessDocument document) {
    return const SizedBox.shrink();
  }
}

class _DelayedFakeDocumentsRepository extends _FakeDocumentsRepository {
  final Completer<void> _createCorrespondentCompleter = Completer<void>();

  @override
  Future<PaperlessFilterOption> createCorrespondent({
    required String name,
  }) async {
    await _createCorrespondentCompleter.future;
    return super.createCorrespondent(name: name);
  }

  void completeCorrespondentCreation() {
    if (!_createCorrespondentCompleter.isCompleted) {
      _createCorrespondentCompleter.complete();
    }
  }
}
