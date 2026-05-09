import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _seedColor = Color(0xFF1D5FD3);

const _darkBackground = Color(0xFF11131C);
const _darkSurfaceLowest = Color(0xFF0C0E16);
const _darkSurfaceLow = Color(0xFF191B24);
const _darkSurface = Color(0xFF1D1F28);
const _darkSurfaceHigh = Color(0xFF282933);
const _darkSurfaceHighest = Color(0xFF33343E);
const _darkPrimary = Color(0xFFB8C4FF);
const _darkPrimaryContainer = Color(0xFF3461FF);
const _darkSecondary = Color(0xFF7AD7C6);
const _darkSecondaryContainer = Color(0xFF00786A);
const _darkOnSurface = Color(0xFFE2E1EE);
const _darkOnSurfaceVariant = Color(0xFFC4C5D8);
const _darkOutline = Color(0xFF8E90A2);
const _darkOutlineVariant = Color(0xFF434656);

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final baseTextTheme = GoogleFonts.manropeTextTheme();

  final baseScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: brightness,
  );
  final colorScheme = isDark
      ? baseScheme.copyWith(
          primary: _darkPrimary,
          onPrimary: const Color(0xFF002486),
          primaryContainer: _darkPrimaryContainer,
          onPrimaryContainer: const Color(0xFFF7F6FF),
          secondary: _darkSecondary,
          onSecondary: const Color(0xFF003730),
          secondaryContainer: _darkSecondaryContainer,
          onSecondaryContainer: const Color(0xFFA0FDEB),
          tertiary: const Color(0xFFFFB599),
          onTertiary: const Color(0xFF5A1C00),
          tertiaryContainer: const Color(0xFFC64700),
          onTertiaryContainer: const Color(0xFFFFF5F2),
          surface: _darkBackground,
          surfaceContainerLowest: _darkSurfaceLowest,
          surfaceContainerLow: _darkSurfaceLow,
          surfaceContainer: _darkSurface,
          surfaceContainerHigh: _darkSurfaceHigh,
          surfaceContainerHighest: _darkSurfaceHighest,
          onSurface: _darkOnSurface,
          onSurfaceVariant: _darkOnSurfaceVariant,
          outline: _darkOutline,
          outlineVariant: _darkOutlineVariant,
          surfaceTint: _darkPrimary,
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
          outlineVariant: const Color(0xFFE1E7F2),
          outline: const Color(0xFFCCD6E6),
          shadow: const Color(0xFF0F172A),
        );
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: isDark
          ? colorScheme.outlineVariant
          : colorScheme.outline.withValues(alpha: 0.7),
    ),
  );
  final fieldShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  );
  final textTheme = baseTextTheme
      .copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.64,
          height: 1.25,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          height: 1.33,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.24,
          height: 1.33,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.43,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.33,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.43,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.33,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.33,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.27,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.27,
        ),
      )
      .apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? _darkBackground : const Color(0xFFF7FAFF),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.24,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLow,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.16)
          : colorScheme.shadow.withValues(alpha: 0.04),
      surfaceTintColor: colorScheme.surfaceTint,
      shape: cardShape,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? colorScheme.outlineVariant : colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    dividerColor: isDark
        ? colorScheme.outlineVariant
        : colorScheme.outlineVariant,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainerLowest
          : const Color(0xFFEEF3FB),
      hintStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primaryContainer, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: fieldShape,
        backgroundColor: isDark
            ? colorScheme.primaryContainer
            : colorScheme.primary,
        foregroundColor: isDark
            ? colorScheme.onPrimaryContainer
            : colorScheme.onPrimary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: fieldShape,
        side: BorderSide(
          color: isDark ? colorScheme.outlineVariant : colorScheme.outline,
        ),
        foregroundColor: colorScheme.onSurface,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      elevation: 0,
      height: 74,
      indicatorColor: isDark
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer.withValues(alpha: 0.5),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          color: isSelected
              ? (isDark ? colorScheme.primary : colorScheme.primary)
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0.2,
        );
      }),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: isDark
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow,
      indicatorColor: isDark
          ? colorScheme.primaryContainer
          : colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileHeight: 56,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerLow,
      selectedColor: isDark
          ? colorScheme.secondaryContainer
          : colorScheme.secondaryContainer.withValues(alpha: 0.2),
      secondarySelectedColor: colorScheme.secondaryContainer,
      side: BorderSide(
        color: isDark ? colorScheme.outlineVariant : colorScheme.outline,
      ),
      labelStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
