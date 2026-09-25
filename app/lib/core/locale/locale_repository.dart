import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// Stores the chosen app language and exposes it synchronously so the
/// network layer can send it as `Accept-Language`.
@lazySingleton
class LocaleRepository {
  LocaleRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'app.language';

  /// The saved language, else the device language when supported, else the
  /// Marathi-first fallback.
  AppLanguage get current =>
      AppLanguage.fromCode(_prefs.getString(_key)) ??
      AppLanguage.fromCode(PlatformDispatcher.instance.locale.languageCode) ??
      AppLanguage.fallback;

  Future<void> save(AppLanguage language) =>
      _prefs.setString(_key, language.code);
}
