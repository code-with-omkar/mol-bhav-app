import 'package:equatable/equatable.dart';

/// Sign-in options the server accepts (`GET /auth/methods`). OTP costs money
/// per SMS, so the server can switch it off and keep free password login.
class LoginMethods extends Equatable {
  const LoginMethods({
    required this.otp,
    required this.password,
    this.google = false,
    this.googleClientId,
  });

  /// Used when the server cannot be asked; password login needs no SMS.
  static const fallback = LoginMethods(otp: false, password: true);

  final bool otp;
  final bool password;

  /// "Continue with Google" — shown only with a [googleClientId].
  final bool google;

  /// OAuth web client id for Google Sign-In (public, not a secret).
  final String? googleClientId;

  bool get showGoogle => google && (googleClientId?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [otp, password, google, googleClientId];
}
