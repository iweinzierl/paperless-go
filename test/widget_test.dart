// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/app/app.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
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

  const fakeFilterOptions = [PaperlessFilterOption(id: 1, name: 'Inbox')];

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> initialValues = const <String, Object>{},
    List<Override> overrides = const <Override>[],
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ...overrides,
        ],
        child: const PaperlessNgxApp(),
      ),
    );
  }

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
    expect(find.text('Welcome back, Jane Doe'), findsOneWidget);
    expect(find.text('Quarterly tax summary.pdf'), findsOneWidget);
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

    expect(find.text('Documents'), findsWidgets);
    expect(find.text('1 documents'), findsOneWidget);
    expect(find.text('Search by title'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text(documentsSortOptions.first.label), findsOneWidget);
    expect(find.text('Tag'), findsOneWidget);
    expect(find.text('Correspondent'), findsOneWidget);
    expect(find.text('Document type'), findsOneWidget);
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
}
