import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/features/app_shell/data/local/app_behavior_preferences.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';

void main() {
  test('reads saved TODO tag ids and legacy names', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.theme_mode': 'dark',
      'app_behavior.todo_tag_ids': <String>['2', '4'],
      'app_behavior.todo_tag_names': <String>['Review', 'Inbox'],
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.themeMode, equals(AppThemeMode.dark));
    expect(settings.normalizedTodoTagIds, equals(const <int>[2, 4]));
    expect(
      settings.normalizedTodoTagNames,
      equals(const <String>['Review', 'Inbox']),
    );
  });

  test(
    'falls back to legacy TODO tag names when ids are unavailable',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{
        'app_behavior.todo_tag_names': <String>['Prüfen'],
      });
      final sharedPreferences = await SharedPreferences.getInstance();
      final preferences = AppBehaviorPreferences(sharedPreferences);

      final settings = preferences.readSettings();

      expect(settings.themeMode, equals(AppThemeMode.light));
      expect(settings.normalizedTodoTagIds, isEmpty);
      expect(settings.normalizedTodoTagNames, equals(const <String>['Prüfen']));
    },
  );

  test('saves TODO tag ids as strings for stable persistence', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    await preferences.saveSettings(
      const AppBehaviorSettings(
        cachePreviewsEnabled: true,
        themeMode: AppThemeMode.dark,
        todoTagIds: <int>[7, 3],
        todoTagNames: <String>['Review', 'Inbox'],
      ),
    );

    expect(
      sharedPreferences.getString('app_behavior.theme_mode'),
      equals('dark'),
    );
    expect(
      sharedPreferences.getStringList('app_behavior.todo_tag_ids'),
      equals(const <String>['7', '3']),
    );
    expect(
      sharedPreferences.getStringList('app_behavior.todo_tag_names'),
      equals(const <String>['Review', 'Inbox']),
    );
  });

  test('defaults to light mode for invalid stored theme values', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{
      'app_behavior.theme_mode': 'sepia',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = AppBehaviorPreferences(sharedPreferences);

    final settings = preferences.readSettings();

    expect(settings.themeMode, equals(AppThemeMode.light));
  });
}
