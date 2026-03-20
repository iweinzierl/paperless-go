import 'package:flutter/material.dart';

const _seedColor = Color(0xFF1F6F8B);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  final baseScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  final colorScheme = isDark
      ? baseScheme.copyWith(
          surface: const Color(0xFF111B20),
          surfaceContainerLowest: const Color(0xFF0D1519),
          surfaceContainerLow: const Color(0xFF142027),
          surfaceContainer: const Color(0xFF17252C),
          surfaceContainerHigh: const Color(0xFF1B2B33),
          surfaceContainerHighest: const Color(0xFF22343D),
          onSurface: const Color(0xFFE7EEF2),
          onSurfaceVariant: const Color(0xFFB5C5CC),
          outline: const Color(0xFF42545D),
          shadow: Colors.black,
        )
      : baseScheme;

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0F171A)
        : const Color(0xFFF4F7F8),
    useMaterial3: true,
    cardTheme: CardThemeData(
      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.22) : null,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: isDark
        ? colorScheme.outline.withValues(alpha: 0.45)
        : colorScheme.outlineVariant,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}
