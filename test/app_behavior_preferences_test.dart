import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/features/app_shell/data/local/app_behavior_preferences.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';

void main() {
  test('reads saved app behavior settings', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.cache_previews_enabled': false,
      'app_behavior.theme_mode': 'dark',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.cachePreviewsEnabled, isFalse);
    expect(settings.appLanguage, equals(AppLanguage.system));
    expect(settings.themeMode, equals(AppThemeMode.dark));
  });

  test(
    'saves app behavior settings and removes obsolete todo tag keys',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'app_behavior.todo_tag_ids': <String>['7', '3'],
        'app_behavior.todo_tag_names': <String>['Review', 'Inbox'],
      });
      final sharedPreferences = await SharedPreferences.getInstance();
      final preferences = AppBehaviorPreferences(sharedPreferences);

      await preferences.saveSettings(
        const AppBehaviorSettings(
          cachePreviewsEnabled: true,
          appLanguage: AppLanguage.german,
          themeMode: AppThemeMode.dark,
        ),
      );

      expect(
        sharedPreferences.getString('app_behavior.app_language'),
        equals('de'),
      );
      expect(
        sharedPreferences.getString('app_behavior.theme_mode'),
        equals('dark'),
      );
      expect(
        sharedPreferences.getStringList('app_behavior.todo_tag_ids'),
        isNull,
      );
      expect(
        sharedPreferences.getStringList('app_behavior.todo_tag_names'),
        isNull,
      );
    },
  );

  test('defaults to light mode for invalid stored theme values', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.theme_mode': 'sepia',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.appLanguage, equals(AppLanguage.system));
    expect(settings.themeMode, equals(AppThemeMode.light));
  });

  test('reads saved app language override', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.app_language': 'fr',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.appLanguage, equals(AppLanguage.french));
  });
}
