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
    return AppBehaviorSettings(
      cachePreviewsEnabled:
          _sharedPreferences.getBool(_cachePreviewsKey) ?? true,
      appLanguage: AppLanguage.fromStorageValue(
        _sharedPreferences.getString(_appLanguageKey),
      ),
      themeMode: AppThemeMode.fromStorageValue(
        _sharedPreferences.getString(_themeModeKey),
      ),
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
    await _sharedPreferences.remove(_todoTagIdsKey);
    await _sharedPreferences.remove(_todoTagsKey);
  }
}
