import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/auth_failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final SessionManager _session;

  @override
  Future<Result<OtpChallenge>> requestOtp(MobileNumber mobile) {
    return runApiCall(() async {
      final response = await _remote.requestOtp(mobile.e164);
      return OtpChallenge(
        mobile: mobile,
        codeLength: response.otpLength,
        resendAfter: Duration(seconds: response.resendAfterSeconds),
      );
    });
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required MobileNumber mobile,
    required String code,
  }) {
    return runApiCall(
      () async {
        final response = await _remote.verifyOtp(mobile.e164, code);
        await _session.signIn(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          onboarded: response.isOnboarded,
        );
        return AuthSession(isOnboarded: response.isOnboarded);
      },
      mapError: (e) => switch (e.response?.statusCode) {
        400 || 401 || 422 => const InvalidOtpFailure(),
        _ => null,
      },
    );
  }
}
