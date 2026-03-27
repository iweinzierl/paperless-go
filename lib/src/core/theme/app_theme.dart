import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _seedColor = Color(0xFF1D5FD3);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

  final baseScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  final colorScheme = isDark
      ? baseScheme.copyWith(
          primary: const Color(0xFF8CB8FF),
          onPrimary: const Color(0xFF062C68),
          secondary: const Color(0xFFD9E6FF),
          onSecondary: const Color(0xFF132B54),
          surface: const Color(0xFF0F1724),
          surfaceContainerLowest: const Color(0xFF080F18),
          surfaceContainerLow: const Color(0xFF182235),
          surfaceContainer: const Color(0xFF1E2A40),
          surfaceContainerHigh: const Color(0xFF25324A),
          surfaceContainerHighest: const Color(0xFF31415F),
          onSurface: const Color(0xFFF2F5FB),
          onSurfaceVariant: const Color(0xFFC6D3EA),
          outline: const Color(0xFF6C7EA1),
          shadow: Colors.black,
        )
      : baseScheme.copyWith(
          primary: const Color(0xFF1D5FD3),
          onPrimary: Colors.white,
          secondary: const Color(0xFFD9E6FF),
          onSecondary: const Color(0xFF1D335F),
          surface: const Color(0xFFF5F8FE),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFFFFFFF),
          surfaceContainer: const Color(0xFFF0F5FD),
          surfaceContainerHigh: const Color(0xFFE8EFFA),
          surfaceContainerHighest: const Color(0xFFDEE7F6),
          onSurface: const Color(0xFF121A29),
          onSurfaceVariant: const Color(0xFF66748E),
          outline: const Color(0xFFCCD6E6),
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
        ? const Color(0xFF070D16)
        : const Color(0xFFF7FAFF),
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
          ? Colors.black.withValues(alpha: 0.34)
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
          ? colorScheme.surfaceContainer
          : const Color(0xFFEEF3FB),
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
      backgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      elevation: 0,
      height: 78,
      indicatorColor: colorScheme.secondaryContainer.withValues(
        alpha: isDark ? 0.78 : 0.5,
      ),
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
      backgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      tileHeight: 56,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
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
