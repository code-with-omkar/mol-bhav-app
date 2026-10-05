import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Gets a Google ID token for the backend (`POST /auth/google`). The app keeps
/// no Google session of its own: after each token it signs out of Google, so
/// the next sign-in shows the account picker again.
///
/// - Android (and iOS later): [authenticate] opens Google's account picker.
/// - Web: Google only allows its own rendered button; tokens arrive on
///   [webIdTokens] after the user clicks it (see `GoogleSignInButton`).
///
/// [webClientId] is the OAuth *web* client id from `GET /auth/methods`: on
/// Android it is the server client id (the token's audience is our backend),
/// on web it is the page's own client id.
@lazySingleton
class GoogleIdTokenSource {
  Future<void>? _initializing;
  String? _initializedFor;

  /// Must complete before [authenticate] or rendering the web button.
  Future<void> ensureInitialized(String webClientId) {
    if (_initializedFor == webClientId && _initializing != null) {
      return _initializing!;
    }
    _initializedFor = webClientId;
    return _initializing = GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );
  }

  /// False on web, where only Google's rendered button may start sign-in.
  bool get canAuthenticate => GoogleSignIn.instance.supportsAuthenticate();

  /// Opens the account picker. Null when the user closes it.
  Future<String?> authenticate() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// ID tokens from the web button.
  Stream<String> get webIdTokens => GoogleSignIn.instance.authenticationEvents
      .map(
        (event) => switch (event) {
          GoogleSignInAuthenticationEventSignIn(:final user) =>
            user.authentication.idToken,
          _ => null,
        },
      )
      .where((token) => token != null)
      .cast<String>();

  /// Forget the Google account on this device after the token was used.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Best effort: nothing depends on it.
    }
  }
}
