import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/client_certificate_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('chooses and removes a client certificate on the login page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
          clientCertificatePickerProvider.overrideWithValue(
            const _FakeClientCertificatePicker(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LoginPage)),
    );
    LoginFormState formState() => container.read(loginControllerProvider);

    // Closed at first: nothing about a certificate is asked for.
    expect(find.text('Choose certificate file'), findsNothing);

    await tester.ensureVisible(find.text('Client certificate (optional)'));
    await tester.tap(find.text('Client certificate (optional)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose certificate file'));
    await tester.tap(find.text('Choose certificate file'));
    await tester.pumpAndSettle();

    expect(find.text('client.p12'), findsOneWidget);
    expect(formState().clientCertificateBytes, <int>[1, 2, 3]);

    final passwordField = find.ancestor(
      of: find.text('Certificate password'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'p12-password');
    await tester.pumpAndSettle();

    expect(formState().clientCertificatePassword, 'p12-password');

    // Removing asks first, and cancelling keeps the certificate.
    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove client certificate?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('client.p12'), findsOneWidget);
    expect(formState().clientCertificate, isNotNull);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.text('client.p12'), findsNothing);
    expect(formState().clientCertificate, isNull);
  });

  testWidgets('shows saved custom headers by name without their values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth.server_url': 'https://example.com/',
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth.custom_headers': jsonEncode(<String, String>{
        'CF-Access-Client-Id': 'client-id.access',
        'CF-Access-Client-Secret': 'client-secret',
      }),
    });
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authTokenStorageProvider.overrideWithValue(
            await AuthTokenStorage.load(
              const FlutterSecureStorage(),
              sharedPreferences,
            ),
          ),
          connectionSecretsStorageProvider.overrideWithValue(
            await ConnectionSecretsStorage.load(
              const FlutterSecureStorage(),
              sharedPreferences,
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The section is open and names the saved headers ...
    expect(find.textContaining('CF-Access-Client-Id'), findsOneWidget);
    expect(find.textContaining('CF-Access-Client-Secret'), findsOneWidget);

    // ... but their values are nowhere on the page, not even in a field.
    expect(find.textContaining('client-secret'), findsNothing);
    expect(find.textContaining('client-id.access'), findsNothing);
    for (final field in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(field.controller.text, isNot(contains('client')));
    }

    // Removing asks first, and cancelling keeps the headers.
    await tester.ensureVisible(find.text('Remove'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove custom headers?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CF-Access-Client-Id'), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: 'auth.custom_headers'),
      isNotNull,
    );

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CF-Access-Client-Id'), findsNothing);
    expect(
      await const FlutterSecureStorage().read(key: 'auth.custom_headers'),
      isNull,
    );
  });
}

class _FakeClientCertificatePicker implements ClientCertificatePicker {
  const _FakeClientCertificatePicker();

  @override
  Future<PickedClientCertificateFile?> pick() async {
    return (fileName: 'client.p12', bytes: Uint8List.fromList(<int>[1, 2, 3]));
  }
}
