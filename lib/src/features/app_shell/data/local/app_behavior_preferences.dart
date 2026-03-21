import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';

class AppBehaviorPreferences {
  const AppBehaviorPreferences(this._sharedPreferences);

  static const _cachePreviewsKey = 'app_behavior.cache_previews_enabled';
  static const _appLanguageKey = 'app_behavior.app_language';
  static const _themeModeKey = 'app_behavior.theme_mode';
  static const _todoTagIdsKey = 'app_behavior.todo_tag_ids';
  static const _todoTagsKey = 'app_behavior.todo_tag_names';

  final SharedPreferences _sharedPreferences;

  AppBehaviorSettings readSettings() {
    final todoTagIds = _readTodoTagIds();
    final todoTagNames =
        _sharedPreferences.getStringList(_todoTagsKey) ??
        (todoTagIds.isEmpty ? const <String>['Prüfen'] : const <String>[]);

    return AppBehaviorSettings(
      cachePreviewsEnabled:
          _sharedPreferences.getBool(_cachePreviewsKey) ?? true,
      appLanguage: AppLanguage.fromStorageValue(
        _sharedPreferences.getString(_appLanguageKey),
      ),
      themeMode: AppThemeMode.fromStorageValue(
        _sharedPreferences.getString(_themeModeKey),
      ),
      todoTagIds: todoTagIds,
      todoTagNames: todoTagNames,
    );
  }

  Future<void> saveSettings(AppBehaviorSettings settings) async {
    await _sharedPreferences.setBool(
      _cachePreviewsKey,
      settings.cachePreviewsEnabled,
    );
    await _sharedPreferences.setString(
      _appLanguageKey,
      settings.appLanguage.storageValue,
    );
    await _sharedPreferences.setString(
      _themeModeKey,
      settings.themeMode.storageValue,
    );
    final todoTagIds = settings.normalizedTodoTagIds
        .map((id) => id.toString())
        .toList(growable: false);
    if (todoTagIds.isEmpty) {
      await _sharedPreferences.remove(_todoTagIdsKey);
    } else {
      await _sharedPreferences.setStringList(_todoTagIdsKey, todoTagIds);
    }

    await _sharedPreferences.setStringList(
      _todoTagsKey,
      settings.normalizedTodoTagNames,
    );
  }

  List<int> _readTodoTagIds() {
    return (_sharedPreferences.getStringList(_todoTagIdsKey) ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList(growable: false);
  }
}
