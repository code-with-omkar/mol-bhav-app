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

/// A Google account with no MolBhav account yet: ask for the mobile number
/// and send it with the same ID token.
final class GooglePhoneRequiredFailure extends Failure {
  const GooglePhoneRequiredFailure();
}

/// Google sign-in could not be verified (expired or forged token).
final class GoogleTokenInvalidFailure extends Failure {
  const GoogleTokenInvalidFailure();
}

/// That Google account is already linked to another MolBhav account.
final class GoogleLinkedElsewhereFailure extends Failure {
  const GoogleLinkedElsewhereFailure();
}

/// Google is the only way into this account: set a password before unlinking.
final class LastSignInMethodFailure extends Failure {
  const LastSignInMethodFailure();
}
