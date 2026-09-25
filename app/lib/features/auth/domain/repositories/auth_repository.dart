import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/mobile_number.dart';
import '../entities/otp_challenge.dart';

abstract interface class AuthRepository {
  /// Sends an OTP by SMS to [mobile].
  Future<Result<OtpChallenge>> requestOtp(MobileNumber mobile);

  /// Verifies [code] and, on success, stores the session.
  /// Fails with `InvalidOtpFailure` when the code is wrong or expired.
  Future<Result<AuthSession>> verifyOtp({
    required MobileNumber mobile,
    required String code,
  });
}
