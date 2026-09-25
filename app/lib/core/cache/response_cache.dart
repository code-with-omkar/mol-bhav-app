import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/locale_repository.dart';

class CachedResponse {
  const CachedResponse({required this.data, required this.savedAt});

  /// The decoded JSON body as the API returned it.
  final Object data;
  final DateTime savedAt;
}

/// Last successful API responses, for offline use. Bodies are stored raw so
/// the repository's normal parsing applies to cached and live data alike.
///
/// Keyed by UI language too, because the API localises names.
@lazySingleton
class ResponseCache {
  ResponseCache(this._prefs, this._locale);

  final SharedPreferences _prefs;
  final LocaleRepository _locale;

  static const _prefix = 'cache.v1.';

  String _key(String key) => '$_prefix${_locale.current.code}.$key';

  Future<void> write(String key, Object data) => _prefs.setString(
    _key(key),
    jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'data': data}),
  );

  CachedResponse? read(String key) {
    final raw = _prefs.getString(_key(key));
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return CachedResponse(
        data: entry['data'] as Object,
        savedAt: DateTime.parse(entry['savedAt'] as String),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }
}
