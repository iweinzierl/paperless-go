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

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
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
