import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/cache/cached_api_call.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/locale/locale_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late ResponseCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'app.language': 'en'});
    prefs = await SharedPreferences.getInstance();
    cache = ResponseCache(prefs, LocaleRepository(prefs));
  });

  test(
    'written data is read back from memory and survives a restart',
    () async {
      await cache.write('alerts.list', [1, 2]);

      expect(cache.read('alerts.list')?.data, [1, 2]);
      // A fresh instance (next launch) decodes it from SharedPreferences.
      final restarted = ResponseCache(prefs, LocaleRepository(prefs));
      expect(restarted.read('alerts.list')?.data, [1, 2]);
    },
  );

  test('invalidate drops exact keys and prefix wildcards only', () async {
    await cache.write('alerts.rules', [1]);
    await cache.write('etag:/a?page=1', {'etag': 'x'});
    await cache.write('etag:/a?page=2', {'etag': 'y'});
    await cache.write('alerts.list', [2]);

    await cache.invalidate(const ['alerts.rules', 'etag:/a*']);

    expect(cache.read('alerts.rules'), isNull);
    expect(cache.read('etag:/a?page=1'), isNull);
    expect(cache.read('etag:/a?page=2'), isNull);
    expect(cache.read('alerts.list')?.data, [2]);
  });

  test('clear empties memory and storage', () async {
    await cache.write('alerts.list', [1]);

    await cache.clear();

    expect(cache.read('alerts.list'), isNull);
    expect(prefs.getKeys().where((k) => k.startsWith('cache.v1.')), isEmpty);
  });

  test('concurrent callers for one key share a single request', () async {
    var calls = 0;
    final gate = Completer<Object>();
    Future<Object> fetch() {
      calls++;
      return gate.future;
    }

    final first = runCachedApiCall(
      cache: cache,
      key: 'k',
      fetch: fetch,
      parse: (j) => j,
    );
    final second = runCachedApiCall(
      cache: cache,
      key: 'k',
      fetch: fetch,
      parse: (j) => j,
    );
    gate.complete([1]);
    final results = await Future.wait([first, second]);

    expect(calls, 1);
    expect(results.every((r) => r is Ok), isTrue);
  });
}
