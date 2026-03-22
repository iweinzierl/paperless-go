import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paperless_ngx_app/src/debug/screenshot_harness.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final sharedPreferences = await SharedPreferences.getInstance();
  final screenshotScenario = maybeParseScreenshotScenario(
    sharedPreferences.getString(screenshotScenarioPreferenceKey),
  );
  final screenshotLanguageCode =
      sharedPreferences.getString('app_behavior.app_language') ?? 'en';
  final overrides = <Override>[
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    if (screenshotScenario != null)
      documentsRepositoryProvider.overrideWithValue(
        ScreenshotDocumentsRepository(languageCode: screenshotLanguageCode),
      ),
  ];

  runApp(
    ProviderScope(
      overrides: overrides,
      child: screenshotScenario == null
          ? const PaperlessNgxApp()
          : ScreenshotHarnessApp(scenario: screenshotScenario),
    ),
  );
}
