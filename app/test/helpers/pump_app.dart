import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/l10n/l10n.dart';
import 'package:mol_bhav/core/theme/app_theme.dart';
import 'package:mol_bhav/core/theme/mb_typography.dart';

/// Theme without google_fonts, so tests never fetch fonts.
final testTheme = AppTheme.light(fonts: platformFontResolver);

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child, {Locale locale = const Locale('en')}) {
    return pumpWidget(
      MaterialApp(
        theme: testTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _delegates,
        home: child,
      ),
    );
  }

  Future<void> pumpRouterApp(RouterConfig<Object> router) {
    return pumpWidget(
      MaterialApp.router(
        theme: testTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _delegates,
        routerConfig: router,
      ),
    );
  }
}
