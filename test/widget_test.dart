// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/app/app.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

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

  const fakeFilterOptions = [PaperlessFilterOption(id: 1, name: 'Inbox')];
  const fakeDrawerStatistics = AppDrawerStatistics(
    documents: 128,
    correspondents: 12,
    tags: 34,
    documentTypes: 7,
  );

  final fakeRecentlyOpenedDocument = RecentlyOpenedDocument(
    id: 99,
    title: 'Rent contract.pdf',
    subtitle: '2026-03-18 10:15 · 6 pages',
    openedAt: DateTime(2026, 3, 20, 9, 45),
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialValues = const <String, Object>{},
    List<Override> overrides = const <Override>[],
  }) async {
    PackageInfo.setMockInitialValues(
      appName: 'Paperless Ngx App',
      packageName: 'paperless_ngx_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(initialValues);
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          appDrawerStatisticsProvider.overrideWith(
            (ref) async => fakeDrawerStatistics,
          ),
          ...overrides,
        ],
        child: const PaperlessNgxApp(),
      ),
    );
  }

  Finder settingsScrollable() => find.byType(Scrollable).first;

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
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
      find.text('Todos'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('TODO tags'), findsOneWidget);
    expect(find.text('Select TODO tags'), findsOneWidget);
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

  testWidgets('shows TODO tag selector in settings', (
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
        'app_behavior.todo_tag_ids': <String>['2'],
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
        documentsPageProvider.overrideWith((ref) async => fakeDocumentsPage),
        tagOptionsProvider.overrideWith(
          (ref) async => const [
            PaperlessFilterOption(id: 1, name: 'Inbox'),
            PaperlessFilterOption(id: 2, name: 'Prüfen'),
          ],
        ),
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
      find.text('Select TODO tags'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select TODO tags'), findsOneWidget);
    expect(find.text('Prüfen'), findsOneWidget);
    expect(
      find.text('Select which server tags should feed the Todos tab.'),
      findsOneWidget,
    );
  });

  testWidgets('shows login page on app start', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Connect to your server'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows home page when a saved session exists', (
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    expect(find.text('Paperless-ngx'), findsOneWidget);
    expect(find.text('Recent uploads'), findsWidgets);
    expect(find.text('Todos'), findsWidgets);
    expect(find.byTooltip('Refresh home'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Welcome back, Jane Doe'), findsNothing);
    expect(
      find.text(
        'The latest 20 documents uploaded to your paperless-ngx server.',
      ),
      findsNothing,
    );
    expect(find.text('Added'), findsNothing);
    expect(find.text('Quarterly tax summary.pdf'), findsOneWidget);
    expect(find.text('2026-03-20 12:00 · 4 pages'), findsOneWidget);
  });

  testWidgets('shows snackbar after manual home refresh', (
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.byTooltip('Refresh home'));
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
    await tester.pumpAndSettle();

    expect(find.text('Document details'), findsOneWidget);
    expect(find.text('Open document'), findsOneWidget);
    expect(find.text('Open original'), findsOneWidget);
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Refresh documents'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('1 documents'), findsOneWidget);
    expect(find.text('Search by title'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(find.text('Sort by'), findsNothing);
    expect(find.text('Tag'), findsNothing);
  });

  testWidgets('shows snackbar after manual documents refresh', (
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh documents'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Documents updated.'), findsOneWidget);
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Tag'), findsOneWidget);
    expect(find.text('Correspondent'), findsOneWidget);
    expect(find.text('Document type'), findsOneWidget);
    expect(find.text('Apply filters'), findsOneWidget);
    expect(find.text(documentsSortOptions.first.label), findsOneWidget);
  });

  testWidgets('shows tagged review documents on the Todos tab', (
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(find.text('Verification queue'), findsOneWidget);
    expect(find.text('Insurance claim.pdf'), findsOneWidget);
    expect(find.text('2026-03-19 08:30 · 2 pages'), findsOneWidget);
  });

  testWidgets('links to settings when no TODO tags are configured', (
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
        'app_behavior.todo_tag_names': <String>[],
        'app_behavior.todo_tag_ids': <String>[],
      },
      overrides: [
        recentUploadsProvider.overrideWith((ref) async => [fakeRecentDocument]),
        todoDocumentsProvider.overrideWith((ref) async => const []),
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

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('No TODO tags configured'), findsOneWidget);
    expect(find.text('Open TODO tag settings'), findsOneWidget);

    await tester.tap(find.text('Open TODO tag settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TODO tags'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('TODO tags'), findsOneWidget);
    expect(find.text('No TODO tags selected yet.'), findsOneWidget);
    expect(
      find.text(
        'Use Select TODO tags below to choose which documents appear in the Todos tab.',
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('128'), findsOneWidget);
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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
        todoDocumentsProvider.overrideWith((ref) async => [fakeTodoDocument]),
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

    await tester.tap(find.widgetWithText(ListTile, 'Copy support summary'));
    await tester.pumpAndSettle();

    expect(find.text('Support summary copied.'), findsOneWidget);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

class _FakeHelpLinkLauncher implements HelpLinkLauncher {
  @override
  Future<void> open(Uri uri) async {}
}
