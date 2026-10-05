import 'package:dio/dio.dart';

import '../cache/response_cache.dart';

/// Conditional GETs: remembers each GET's `ETag` with the (unwrapped) data and
/// sends `If-None-Match` next time. When the API answers `304 Not Modified`
/// the stored data is returned as a normal 200 — the screen gets it without
/// the body being downloaded again.
///
/// Entries live in [ResponseCache] (per language, cleared on log out), so a
/// 304 can never hand one user's data to another.
///
/// Add it after [EnvelopeInterceptor]: responses pass interceptors in order,
/// so the data stored here is already unwrapped, exactly what callers expect.
class ETagInterceptor extends Interceptor {
  ETagInterceptor(this._cache);

  final ResponseCache _cache;

  /// Set in `Options.extra` to always download the full body.
  static const skip = 'etag.skip';

  static String _key(RequestOptions o) => 'etag:${o.uri}';

  bool _applies(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' &&
      o.extra[skip] != true &&
      o.responseType == ResponseType.json;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_applies(options)) {
      final stored = _cache.read(_key(options))?.data;
      if (stored is Map && stored['etag'] is String) {
        options.headers['If-None-Match'] = stored['etag'];
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    final etag = response.headers.value('etag');
    if (_applies(options) &&
        response.statusCode == 200 &&
        etag != null &&
        response.data != null) {
      await _cache.write(_key(options), {'etag': etag, 'body': response.data});
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (err.response?.statusCode == 304 && _applies(options)) {
      final stored = _cache.read(_key(options))?.data;
      if (stored is Map && stored.containsKey('body')) {
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: stored['body'],
            statusCode: 200,
            headers: err.response!.headers,
          ),
        );
      }
    }
    handler.next(err);
  }
}
