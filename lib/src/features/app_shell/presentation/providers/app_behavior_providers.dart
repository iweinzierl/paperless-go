import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/data/local/app_behavior_preferences.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';

final appBehaviorPreferencesProvider = Provider<AppBehaviorPreferences>((ref) {
  return AppBehaviorPreferences(ref.watch(sharedPreferencesProvider));
});

final appBehaviorSettingsProvider =
    NotifierProvider<AppBehaviorSettingsController, AppBehaviorSettings>(
      AppBehaviorSettingsController.new,
    );

class AppBehaviorSettingsController extends Notifier<AppBehaviorSettings> {
  AppBehaviorPreferences get _preferences =>
      ref.read(appBehaviorPreferencesProvider);

  @override
  AppBehaviorSettings build() => _preferences.readSettings();

  void setCachePreviewsEnabled(bool value) {
    state = state.copyWith(cachePreviewsEnabled: value);
    unawaited(_preferences.saveSettings(state));
  }

  void setAppLanguage(AppLanguage value) {
    state = state.copyWith(appLanguage: value);
    unawaited(_preferences.saveSettings(state));
  }

  void setThemeMode(AppThemeMode value) {
    state = state.copyWith(themeMode: value);
    unawaited(_preferences.saveSettings(state));
  }

  void setTodoTagSelection({
    required List<int> tagIds,
    required List<String> tagNames,
  }) {
    state = state.copyWith(todoTagIds: tagIds, todoTagNames: tagNames);
    unawaited(_preferences.saveSettings(state));
  }
}
