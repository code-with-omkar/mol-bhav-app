import 'package:flutter/material.dart';

import 'mb_colors.dart';
import 'mb_typography.dart';

/// Builds the Material theme from the MolBhav tokens.
abstract final class AppTheme {
  static ThemeData light({MbFontResolver fonts = googleFontResolver}) =>
      _build(MbColors.light, Brightness.light, fonts);

  static ThemeData dark({MbFontResolver fonts = googleFontResolver}) =>
      _build(MbColors.dark, Brightness.dark, fonts);

  static ThemeData _build(
    MbColors c,
    Brightness brightness,
    MbFontResolver fonts,
  ) {
    final type = MbTypography.resolve(fonts);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.priceUp,
      onError: c.onPrimary,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerLowest: c.surfaceCard,
      outline: c.borderStrong,
      outlineVariant: c.border,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: type.display,
        headlineMedium: type.h1,
        titleLarge: type.h2,
        titleMedium: type.title,
        bodyMedium: type.body,
        bodySmall: type.caption,
        labelSmall: type.label,
      ).apply(bodyColor: c.ink, displayColor: c.ink),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.hero,
        contentTextStyle: type.body.copyWith(color: c.inkOnHero),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [c, type],
    );
  }
}

extension MbThemeX on BuildContext {
  MbColors get mbColors => Theme.of(this).extension<MbColors>()!;
  MbTypography get mbText => Theme.of(this).extension<MbTypography>()!;
}
