import '../../../core/error/failure.dart';

/// The entered OTP is wrong or has expired.
final class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure();
}
