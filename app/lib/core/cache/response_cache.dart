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

/// Last successful API responses, shown instantly on the next launch and used
/// offline. Bodies are stored raw so
/// the repository's normal parsing applies to cached and live data alike.
///
/// Keyed by UI language too, because the API localises names.
///
/// Two levels: decoded entries are kept in memory, so returning to a screen
/// does not decode JSON again; SharedPreferences keeps them across launches.
@lazySingleton
class ResponseCache {
  ResponseCache(this._prefs, this._locale);

  final SharedPreferences _prefs;
  final LocaleRepository _locale;
  final Map<String, CachedResponse> _memory = {};

  static const _prefix = 'cache.v1.';

  /// Entries bigger than this are kept in memory only (SharedPreferences is
  /// loaded whole at startup, so huge strings would slow every launch).
  static const maxPersistedChars = 512 * 1024;

  String _key(String key) => '$_prefix${_locale.current.code}.$key';

  Future<void> write(String key, Object data) async {
    final fullKey = _key(key);
    final entry = CachedResponse(data: data, savedAt: DateTime.now());
    _memory[fullKey] = entry;
    final encoded = jsonEncode({
      'savedAt': entry.savedAt.toIso8601String(),
      'data': data,
    });
    if (encoded.length <= maxPersistedChars) {
      await _prefs.setString(fullKey, encoded);
    } else {
      await _prefs.remove(fullKey);
    }
  }

  CachedResponse? read(String key) {
    final fullKey = _key(key);
    final inMemory = _memory[fullKey];
    if (inMemory != null) return inMemory;

    final raw = _prefs.getString(fullKey);
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      return _memory[fullKey] = CachedResponse(
        data: entry['data'] as Object,
        savedAt: DateTime.parse(entry['savedAt'] as String),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Drops [keys] in every language, so the next read goes to the API.
  /// A key ending in `*` drops every entry starting with it (e.g. all pages).
  Future<void> invalidate(Iterable<String> keys) async {
    bool matches(String fullKey) {
      if (!fullKey.startsWith(_prefix)) return false;
      // cache.v1.<lang>.<key>
      final rest = fullKey.substring(_prefix.length);
      final dot = rest.indexOf('.');
      if (dot < 0) return false;
      final bare = rest.substring(dot + 1);
      return keys.any(
        (k) => k.endsWith('*')
            ? bare.startsWith(k.substring(0, k.length - 1))
            : bare == k,
      );
    }

    _memory.removeWhere((k, _) => matches(k));
    for (final key in _prefs.getKeys().where(matches).toList()) {
      await _prefs.remove(key);
    }
  }

  Future<void> clear() async {
    _memory.clear();
    for (final key
        in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await _prefs.remove(key);
    }
  }
}
