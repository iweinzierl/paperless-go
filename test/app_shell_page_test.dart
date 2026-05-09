import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  testWidgets('opens scan document flow from the mobile bottom menu', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(999, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          appShellTabProvider.overrideWith((ref) => 2),
          appDrawerMinimizedProvider.overrideWith((ref) => false),
          appDrawerStatisticsProvider.overrideWith(
            (ref) async => fakeDrawerStatistics,
          ),
          donationConfigurationProvider.overrideWith(
            (ref) => const DonationConfiguration(
              urlTemplate: '',
              currencyCode: 'EUR',
              suggestedAmount: 1,
            ),
          ),
          authDisplaySessionProvider.overrideWith((ref) => fakeSession),
          recentUploadsProvider.overrideWith((ref) async => const []),
          reviewDocumentsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomAppBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Start a new scan'), findsOneWidget);
    expect(find.text('Upload scan'), findsNothing);
  });
}
