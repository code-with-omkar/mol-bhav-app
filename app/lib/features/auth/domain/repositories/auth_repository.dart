import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/login_methods.dart';
import '../entities/mobile_number.dart';
import '../entities/otp_challenge.dart';

abstract interface class AuthRepository {
  /// Which sign-in options the server currently accepts.
  Future<Result<LoginMethods>> getLoginMethods();

  /// Sends an OTP by SMS to [mobile].
  Future<Result<OtpChallenge>> requestOtp(MobileNumber mobile);

  /// Verifies [code] and, on success, stores the session.
  /// Fails with `InvalidOtpFailure` when the code is wrong or expired.
  Future<Result<AuthSession>> verifyOtp({
    required MobileNumber mobile,
    required String code,
  });

  /// Signs in with a password and stores the session.
  /// Fails with `InvalidCredentialsFailure` when the number or password is wrong.
  Future<Result<AuthSession>> loginWithPassword({
    required MobileNumber mobile,
    required String password,
  });

  /// Creates an account with a password, then stores the session.
  /// Fails with `AccountExistsFailure` when the number is already registered.
  Future<Result<AuthSession>> registerWithPassword({
    required MobileNumber mobile,
    required String password,
  });
}
