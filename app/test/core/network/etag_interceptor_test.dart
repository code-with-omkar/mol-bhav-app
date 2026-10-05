import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/locale/locale_repository.dart';
import 'package:mol_bhav/core/network/etag_interceptor.dart';
import 'package:mol_bhav/core/network/interceptors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers 200 + ETag the first time, then 304 when `If-None-Match` matches.
class _FakeAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.headers['If-None-Match'] == 'W/"v1"') {
      return ResponseBody.fromString(
        '',
        304,
        headers: {
          'etag': ['W/"v1"'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [
          {'code': 'onion'},
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'etag': ['W/"v1"'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a 304 is served from the stored body as a normal 200', () async {
    SharedPreferences.setMockInitialValues({'app.language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final cache = ResponseCache(prefs, LocaleRepository(prefs));
    final adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.addAll([EnvelopeInterceptor(), ETagInterceptor(cache)]);

    final first = await dio.get<List<dynamic>>('/catalog/categories');
    final second = await dio.get<List<dynamic>>('/catalog/categories');

    expect(first.data, [
      {'code': 'onion'},
    ]);
    expect(adapter.requests.last.headers['If-None-Match'], 'W/"v1"');
    expect(second.statusCode, 200);
    expect(second.data, first.data);
  });
}
