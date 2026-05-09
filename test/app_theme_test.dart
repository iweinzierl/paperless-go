import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('app behavior defaults use system theme mode', () {
    const settings = AppBehaviorSettings.defaults();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.themeMode.materialThemeMode, ThemeMode.system);
  });

  test('buildAppTheme configures the dark archivist palette', () {
    final theme = buildAppTheme(brightness: Brightness.dark);

    expect(theme.colorScheme.surface, const Color(0xFF11131C));
    expect(theme.colorScheme.surfaceContainer, const Color(0xFF1D1F28));
    expect(theme.colorScheme.primaryContainer, const Color(0xFF3461FF));
    expect(theme.colorScheme.secondaryContainer, const Color(0xFF00786A));
    expect(theme.cardTheme.color, const Color(0xFF1D1F28));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF11131C));
    expect(theme.inputDecorationTheme.fillColor, const Color(0xFF0C0E16));
    expect(theme.navigationDrawerTheme.indicatorColor, const Color(0xFF3461FF));
  });

  test('buildAppTheme uses tighter shapes and Manrope typography', () {
    final theme = buildAppTheme(brightness: Brightness.dark);
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final buttonShape =
        theme.filledButtonTheme.style!.shape!.resolve(<WidgetState>{})!
            as RoundedRectangleBorder;
    final inputBorder =
        theme.inputDecorationTheme.border! as OutlineInputBorder;

    expect(theme.textTheme.bodyLarge?.fontFamily, contains('Manrope'));
    expect(cardShape.borderRadius, BorderRadius.circular(12));
    expect(buttonShape.borderRadius, BorderRadius.circular(8));
    expect(inputBorder.borderRadius, BorderRadius.circular(8));
  });

  test('buildAppTheme keeps the light theme distinct from the dark theme', () {
    final lightTheme = buildAppTheme();
    final darkTheme = buildAppTheme(brightness: Brightness.dark);

    expect(
      lightTheme.colorScheme.surface,
      isNot(darkTheme.colorScheme.surface),
    );
    expect(
      lightTheme.colorScheme.primaryContainer,
      isNot(darkTheme.colorScheme.primaryContainer),
    );
    expect(
      lightTheme.navigationDrawerTheme.indicatorColor,
      isNot(darkTheme.navigationDrawerTheme.indicatorColor),
    );
  });
}
