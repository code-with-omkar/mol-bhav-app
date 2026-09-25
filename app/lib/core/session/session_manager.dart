import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../cache/response_cache.dart';
import '../storage/token_storage.dart';

enum SessionStatus {
  /// No stored session: the user must log in.
  signedOut,

  /// Logged in, business profile / categories not finished.
  onboarding,

  /// Logged in and onboarded.
  signedIn,
}

/// Single owner of the session. The router listens to it to skip Login when
/// a session exists and to return to Login when it ends.
@lazySingleton
class SessionManager extends ChangeNotifier {
  SessionManager(this._tokens, this._cache);

  final TokenStorage _tokens;
  final ResponseCache _cache;

  SessionStatus _status = SessionStatus.signedOut;
  bool _expired = false;

  SessionStatus get status => _status;

  bool get hasSession => _status != SessionStatus.signedOut;

  /// Reads the stored session at startup. A stored refresh token counts as a
  /// session: an expired access token is renewed on the first 401.
  Future<void> restore() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      _status = SessionStatus.signedOut;
    } else {
      _status = await _tokens.readOnboarded()
          ? SessionStatus.signedIn
          : SessionStatus.onboarding;
    }
  }

  Future<void> signIn({
    required String accessToken,
    required String refreshToken,
    required bool onboarded,
  }) async {
    await _tokens.save(accessToken: accessToken, refreshToken: refreshToken);
    await _tokens.saveOnboarded(onboarded);
    _expired = false;
    _set(onboarded ? SessionStatus.signedIn : SessionStatus.onboarding);
  }

  Future<void> completeOnboarding() async {
    await _tokens.saveOnboarded(true);
    if (_status == SessionStatus.onboarding) _set(SessionStatus.signedIn);
  }

  /// User-initiated log out.
  Future<void> signOut() => _end(expired: false);

  /// The session could not be renewed (unrecoverable 401).
  Future<void> expire() async {
    if (!hasSession) return;
    await _end(expired: true);
  }

  /// Returns `true` once after an expiry, so Login can say why it is shown.
  bool consumeExpiredNotice() {
    final expired = _expired;
    _expired = false;
    return expired;
  }

  Future<void> _end({required bool expired}) async {
    await _tokens.clear();
    // Cached prices belong to the signed-in user.
    await _cache.clear();
    _expired = expired;
    _set(SessionStatus.signedOut);
  }

  void _set(SessionStatus status) {
    if (status == _status) return;
    _status = status;
    notifyListeners();
  }
}
