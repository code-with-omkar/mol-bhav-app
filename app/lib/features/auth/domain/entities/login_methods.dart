import 'package:equatable/equatable.dart';

/// Sign-in options the server accepts (`GET /auth/methods`). OTP costs money
/// per SMS, so the server can switch it off and keep free password login.
class LoginMethods extends Equatable {
  const LoginMethods({required this.otp, required this.password});

  /// Used when the server cannot be asked; password login needs no SMS.
  static const fallback = LoginMethods(otp: false, password: true);

  final bool otp;
  final bool password;

  @override
  List<Object?> get props => [otp, password];
}
