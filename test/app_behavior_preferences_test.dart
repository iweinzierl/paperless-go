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
    expect(settings.biometricLockEnabled, isFalse);
    expect(settings.appLockTimeout, equals(AppLockTimeout.after30Seconds));
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
          biometricLockEnabled: true,
          appLockTimeout: AppLockTimeout.after1Minute,
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
        sharedPreferences.getBool('app_behavior.biometric_lock_enabled'),
        isTrue,
      );
      expect(
        sharedPreferences.getString('app_behavior.app_lock_timeout'),
        equals('1_minute'),
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
    expect(settings.appLockTimeout, equals(AppLockTimeout.after30Seconds));
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

  test('reads saved biometric app lock settings', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.biometric_lock_enabled': true,
      'app_behavior.app_lock_timeout': '5_minutes',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.biometricLockEnabled, isTrue);
    expect(settings.appLockTimeout, equals(AppLockTimeout.after5Minutes));
  });

  test('marks biometric prompt as shown', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    expect(preferences.hasShownBiometricPrompt(), isFalse);

    await preferences.markBiometricPromptShown();

    expect(preferences.hasShownBiometricPrompt(), isTrue);
  });
}
