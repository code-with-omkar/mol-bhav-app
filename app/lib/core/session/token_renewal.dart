import 'package:injectable/injectable.dart';

import '../storage/token_storage.dart';
import 'token_refresher.dart';

/// Rotates the tokens now instead of on the next 401, so claims that just
/// changed server-side (the subscription tier after a payment) apply at once
/// rather than when the access token happens to expire.
///
/// Best effort: any failure leaves the current tokens in place, and the
/// normal 401 path in `AuthInterceptor` still renews or ends the session.
@lazySingleton
class TokenRenewal {
  TokenRenewal(this._tokens, this._refresher);

  final TokenStorage _tokens;
  final TokenRefresher _refresher;

  Future<void> renewNow() async {
    try {
      final refreshToken = await _tokens.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return;
      final pair = await _refresher.refresh(refreshToken);
      if (pair == null) return;
      await _tokens.save(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
      );
    } on Object {
      // Offline, or a parallel refresh rotated first: nothing to do.
    }
  }
}
