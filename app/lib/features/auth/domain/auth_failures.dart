import '../../../core/error/failure.dart';

/// The entered OTP is wrong or has expired.
final class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure();
}

/// Wrong mobile number or password. The server never says which.
final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure();
}

/// "Create account" with a number that already has an account.
final class AccountExistsFailure extends Failure {
  const AccountExistsFailure();
}
