import 'package:dio/dio.dart';

import '../locale/locale_repository.dart';
import '../session/session_manager.dart';
import '../session/token_refresher.dart';
import '../storage/token_storage.dart';

/// Attaches the bearer token and, on a 401, renews it once and retries the
/// request. Concurrent 401s share a single refresh. When renewal is not
/// possible the session is expired, which sends the user to Login.
class AuthInterceptor extends Interceptor {
  /// [_dio] is the client this interceptor is attached to; retries go
  /// through it so the other interceptors apply again.
  AuthInterceptor(this._tokens, this._refresher, this._session, this._dio);

  /// Set in `Options.extra` for calls made before a session exists (OTP),
  /// whose 401 means "wrong code", not "session expired".
  static const skipAuth = 'auth.skip';
  static const _retried = 'auth.retried';

  final TokenStorage _tokens;
  final TokenRefresher _refresher;
  final SessionManager _session;
  final Dio _dio;
  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra[skipAuth] == true ||
        !_session.hasSession) {
      return handler.next(err);
    }
    if (options.extra[_retried] == true) {
      // Still 401 with a fresh token: the session is no longer valid.
      await _session.expire();
      return handler.next(err);
    }

    final String? token;
    try {
      token = await (_refreshing ??= _refresh().whenComplete(
        () => _refreshing = null,
      ));
    } on Object {
      // Transient refresh failure (e.g. offline): keep the session.
      return handler.next(err);
    }
    if (token == null) {
      await _session.expire();
      return handler.next(err);
    }

    options
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retried] = true;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// New access token, or `null` when the session cannot be renewed.
  Future<String?> _refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final pair = await _refresher.refresh(refreshToken);
    if (pair == null) return null;
    await _tokens.save(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
    );
    return pair.accessToken;
  }
}

/// Sends the UI language so the API returns localised names and messages.
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._locale);

  final LocaleRepository _locale;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _locale.current.code;
    handler.next(options);
  }
}
