import '../../../core/error/result.dart';

/// "Forgot password": a code to the mobile number, then a new password.
abstract interface class PasswordResetRepository {
  /// Succeeds whether or not the number has an account.
  Future<Result<void>> requestCode(String phoneNumber);

  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  });
}
