import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../network/api_config.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Exchanges a refresh token for new tokens.
///
/// Returns `null` when the refresh token is rejected or refreshing is not
/// possible; the session then ends. Throw only for transient failures
/// (e.g. no network), which keep the session.
abstract interface class TokenRefresher {
  Future<TokenPair?> refresh(String refreshToken);
}

/// Calls `POST /auth/token/refresh` on a dedicated Dio instance (no auth
/// interceptors) to avoid infinite 401 loops. Parses the `ApiResponse<SessionResponse>`
/// envelope manually since `EnvelopeInterceptor` is not on this Dio.
@LazySingleton(as: TokenRefresher)
class DioTokenRefresher implements TokenRefresher {
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  @override
  Future<TokenPair?> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/token/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      if (body == null) return null;
      final data = (body['data'] ?? body) as Map<String, dynamic>?;
      if (data == null) return null;
      final accessToken = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (accessToken == null || newRefresh == null) return null;
      return TokenPair(accessToken: accessToken, refreshToken: newRefresh);
    } on DioException catch (e) {
      // Rejected token (400 malformed, 401 invalid/expired/reused, 403
      // account blocked): end the session. Anything else — offline, timeout,
      // 5xx, 409 "rotated by a parallel refresh" — is transient: rethrow so
      // the session survives and the next 401 tries again.
      if (_rejected.contains(e.response?.statusCode)) return null;
      rethrow;
    }
  }

  static const _rejected = {400, 401, 403};
}
