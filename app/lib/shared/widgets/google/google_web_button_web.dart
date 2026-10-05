import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google's own "Sign in with Google" button — on web sign-in may only start
/// from it. The resulting token arrives on `GoogleIdTokenSource.webIdTokens`.
Widget googleWebButton() => web.renderButton();
