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

class AppBehaviorSettings {
  const AppBehaviorSettings({
    required this.cachePreviewsEnabled,
    required this.themeMode,
    required this.todoTagIds,
    required this.todoTagNames,
  });

  const AppBehaviorSettings.defaults()
    : cachePreviewsEnabled = true,
      themeMode = AppThemeMode.light,
      todoTagIds = const <int>[],
      todoTagNames = const <String>['Prüfen'];

  final bool cachePreviewsEnabled;
  final AppThemeMode themeMode;
  final List<int> todoTagIds;
  final List<String> todoTagNames;

  List<int> get normalizedTodoTagIds {
    return todoTagIds.where((id) => id > 0).toSet().toList(growable: false);
  }

  List<String> get normalizedTodoTagNames {
    return todoTagNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  AppBehaviorSettings copyWith({
    bool? cachePreviewsEnabled,
    AppThemeMode? themeMode,
    List<int>? todoTagIds,
    List<String>? todoTagNames,
  }) {
    return AppBehaviorSettings(
      cachePreviewsEnabled: cachePreviewsEnabled ?? this.cachePreviewsEnabled,
      themeMode: themeMode ?? this.themeMode,
      todoTagIds: todoTagIds ?? this.todoTagIds,
      todoTagNames: todoTagNames ?? this.todoTagNames,
    );
  }
}
