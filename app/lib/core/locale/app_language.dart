import 'dart:ui';

/// Languages offered in the app, each labelled in its own script.
///
/// Native names are not translated: a user must recognise their language
/// whatever the current UI language is.
enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  marathi('mr', 'मराठी'),
  gujarati('gu', 'ગુજરાતી'),
  tamil('ta', 'தமிழ்'),
  telugu('te', 'తెలుగు'),
  kannada('kn', 'ಕನ್ನಡ');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  /// Marathi-first, per the product brief.
  static const fallback = AppLanguage.marathi;

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
