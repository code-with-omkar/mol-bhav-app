import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/google_id_token_source.dart';
import '../../../core/di/injection.dart';
import '../mb_button.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart';

/// "Continue with Google". Hands a Google ID token to [onIdToken]; the caller
/// sends it to the API. On web it renders Google's button (required there),
/// elsewhere our own button opens the account picker.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.clientId,
    required this.label,
    required this.onIdToken,
    this.onError,
    this.enabled = true,
    this.busy = false,
  });

  /// OAuth web client id from `GET /auth/methods`.
  final String clientId;
  final String label;
  final ValueChanged<String> onIdToken;

  /// Google Sign-In itself failed (not a cancel).
  final VoidCallback? onError;
  final bool enabled;
  final bool busy;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final _source = getIt<GoogleIdTokenSource>();
  late final Future<void> _ready = _source.ensureInitialized(widget.clientId);
  StreamSubscription<String>? _webTokens;

  @override
  void initState() {
    super.initState();
    _ready.then((_) {
      if (!mounted || _source.canAuthenticate) return;
      _webTokens = _source.webIdTokens.listen(_deliver);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _webTokens?.cancel();
    super.dispose();
  }

  void _deliver(String token) {
    if (!mounted || !widget.enabled) return;
    widget.onIdToken(token);
    unawaited(_source.signOut());
  }

  Future<void> _pick() async {
    try {
      await _ready;
      final token = await _source.authenticate();
      if (token != null) _deliver(token);
    } on Object {
      widget.onError?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        final ready =
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError;
        if (ready && !_source.canAuthenticate) {
          return Center(child: googleWebButton());
        }
        return MbButton(
          label: widget.label,
          variant: MbButtonVariant.secondary,
          size: MbButtonSize.lg,
          block: true,
          isLoading: widget.busy,
          onPressed: ready && widget.enabled && !widget.busy ? _pick : null,
        );
      },
    );
  }
}
