import 'package:injectable/injectable.dart';

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

/// PENDING: the backend's refresh-token contract has not been shared.
///
/// Until it is, no refresh is attempted, so an expired access token ends the
/// session and returns the user to Login. When the contract is known, add a
/// Dio-backed implementation (using a Dio instance *without* the auth
/// interceptor) and bind it here instead.
@LazySingleton(as: TokenRefresher)
class PendingTokenRefresher implements TokenRefresher {
  @override
  Future<TokenPair?> refresh(String refreshToken) async => null;
}
