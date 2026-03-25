import 'package:flutter/material.dart';

enum AppThemeMode {
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark);

  const AppThemeMode(this.storageValue, this.materialThemeMode);

  final String storageValue;
  final ThemeMode materialThemeMode;

  static AppThemeMode fromStorageValue(String? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => AppThemeMode.light,
    );
  }
}

enum AppLanguage {
  system('system', null),
  english('en', Locale('en')),
  german('de', Locale('de')),
  french('fr', Locale('fr')),
  italian('it', Locale('it')),
  spanish('es', Locale('es'));

  const AppLanguage(this.storageValue, this.locale);

  final String storageValue;
  final Locale? locale;

  static AppLanguage fromStorageValue(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.storageValue == value,
      orElse: () => AppLanguage.system,
    );
  }
}

class AppBehaviorSettings {
  const AppBehaviorSettings({
    required this.cachePreviewsEnabled,
    required this.appLanguage,
    required this.themeMode,
  });

  const AppBehaviorSettings.defaults()
    : cachePreviewsEnabled = true,
      appLanguage = AppLanguage.system,
      themeMode = AppThemeMode.light;

  final bool cachePreviewsEnabled;
  final AppLanguage appLanguage;
  final AppThemeMode themeMode;

  AppBehaviorSettings copyWith({
    bool? cachePreviewsEnabled,
    AppLanguage? appLanguage,
    AppThemeMode? themeMode,
  }) {
    return AppBehaviorSettings(
      cachePreviewsEnabled: cachePreviewsEnabled ?? this.cachePreviewsEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
