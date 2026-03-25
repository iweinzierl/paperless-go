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

enum AppLockTimeout {
  immediate('immediate', Duration.zero),
  after30Seconds('30_seconds', Duration(seconds: 30)),
  after1Minute('1_minute', Duration(minutes: 1)),
  after5Minutes('5_minutes', Duration(minutes: 5));

  const AppLockTimeout(this.storageValue, this.duration);

  final String storageValue;
  final Duration duration;

  static AppLockTimeout fromStorageValue(String? value) {
    return AppLockTimeout.values.firstWhere(
      (timeout) => timeout.storageValue == value,
      orElse: () => AppLockTimeout.after30Seconds,
    );
  }
}

class AppBehaviorSettings {
  const AppBehaviorSettings({
    required this.cachePreviewsEnabled,
    required this.appLanguage,
    required this.themeMode,
    required this.biometricLockEnabled,
    required this.appLockTimeout,
  });

  const AppBehaviorSettings.defaults()
    : cachePreviewsEnabled = true,
      appLanguage = AppLanguage.system,
      themeMode = AppThemeMode.light,
      biometricLockEnabled = false,
      appLockTimeout = AppLockTimeout.after30Seconds;

  final bool cachePreviewsEnabled;
  final AppLanguage appLanguage;
  final AppThemeMode themeMode;
  final bool biometricLockEnabled;
  final AppLockTimeout appLockTimeout;

  AppBehaviorSettings copyWith({
    bool? cachePreviewsEnabled,
    AppLanguage? appLanguage,
    AppThemeMode? themeMode,
    bool? biometricLockEnabled,
    AppLockTimeout? appLockTimeout,
  }) {
    return AppBehaviorSettings(
      cachePreviewsEnabled: cachePreviewsEnabled ?? this.cachePreviewsEnabled,
      appLanguage: appLanguage ?? this.appLanguage,
      themeMode: themeMode ?? this.themeMode,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      appLockTimeout: appLockTimeout ?? this.appLockTimeout,
    );
  }
}
