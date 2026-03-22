import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paperless_ngx_app/src/debug/screenshot_harness.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final sharedPreferences = await SharedPreferences.getInstance();
  final screenshotScenario = maybeParseScreenshotScenario(
    sharedPreferences.getString(screenshotScenarioPreferenceKey),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: screenshotScenario == null
          ? const PaperlessNgxApp()
          : ScreenshotHarnessApp(scenario: screenshotScenario),
    ),
  );
}
