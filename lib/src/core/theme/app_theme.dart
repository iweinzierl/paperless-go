import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _seedColor = Color(0xFF0D7A6A);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

  final baseScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  final colorScheme = isDark
      ? baseScheme.copyWith(
          primary: const Color(0xFF48B4A2),
          onPrimary: const Color(0xFF032D28),
          secondary: const Color(0xFFB7D7D1),
          onSecondary: const Color(0xFF062A25),
          surface: const Color(0xFF0F1B1A),
          surfaceContainerLowest: const Color(0xFF0B1413),
          surfaceContainerLow: const Color(0xFF122120),
          surfaceContainer: const Color(0xFF172827),
          surfaceContainerHigh: const Color(0xFF1C302F),
          surfaceContainerHighest: const Color(0xFF244140),
          onSurface: const Color(0xFFF2F6F4),
          onSurfaceVariant: const Color(0xFFB5C8C3),
          outline: const Color(0xFF4F6662),
          shadow: Colors.black,
        )
      : baseScheme.copyWith(
          primary: const Color(0xFF0D7A6A),
          onPrimary: Colors.white,
          secondary: const Color(0xFFCFE5E0),
          onSecondary: const Color(0xFF113632),
          surface: const Color(0xFFF5FAF8),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFFFFFFF),
          surfaceContainer: const Color(0xFFF2F7F5),
          surfaceContainerHigh: const Color(0xFFEAF2EF),
          surfaceContainerHighest: const Color(0xFFE2ECE8),
          onSurface: const Color(0xFF0F1D1A),
          onSurfaceVariant: const Color(0xFF60746E),
          outline: const Color(0xFFCBD8D3),
          shadow: const Color(0xFF0F172A),
        );
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(28),
  );
  final fieldShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
  );
  final textTheme = baseTextTheme
      .copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 52),
        displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 42),
        displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: 30),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 30),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 26),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 22),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 15),
        titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 13),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 15),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 13),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 11.5),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 10.5),
      )
      .apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF091312)
        : const Color(0xFFF7FBFA),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.24)
          : colorScheme.shadow.withValues(alpha: 0.08),
      surfaceTintColor: colorScheme.surfaceTint,
      shape: cardShape,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: isDark
          ? colorScheme.outline.withValues(alpha: 0.45)
          : colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    dividerColor: isDark
        ? colorScheme.outline.withValues(alpha: 0.45)
        : colorScheme.outlineVariant,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainerHigh
          : const Color(0xFFEFF3F2),
      hintStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 58),
        shape: fieldShape,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: fieldShape,
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.6 : 0.8),
        ),
        foregroundColor: colorScheme.onSurface,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      elevation: 0,
      height: 78,
      indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.3,
        );
      }),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      tileHeight: 56,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
