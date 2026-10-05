import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/auth_failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/login_methods.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final SessionManager _session;

  @override
  Future<Result<LoginMethods>> getLoginMethods() {
    return runApiCall(() async {
      final response = await _remote.getLoginMethods();
      return LoginMethods(
        otp: response.otp,
        password: response.password,
        google: response.google,
        googleClientId: response.googleClientId,
      );
    });
  }

  @override
  Future<Result<AuthSession>> loginWithPassword({
    required MobileNumber mobile,
    required String password,
  }) {
    return runApiCall(
      () async =>
          _startSession(await _remote.loginWithPassword(mobile.e164, password)),
      mapError: (e) => switch (e.response?.statusCode) {
        400 => const InvalidCredentialsFailure(),
        _ => null,
      },
    );
  }

  @override
  Future<Result<AuthSession>> registerWithPassword({
    required MobileNumber mobile,
    required String password,
  }) {
    return runApiCall(
      () async => _startSession(
        await _remote.registerWithPassword(mobile.e164, password),
      ),
      mapError: (e) => switch (e.response?.statusCode) {
        409 => const AccountExistsFailure(),
        _ => null,
      },
    );
  }

  @override
  Future<Result<AuthSession>> loginWithGoogle({
    required String idToken,
    MobileNumber? mobile,
  }) {
    return runApiCall(
      () async =>
          _startSession(await _remote.loginWithGoogle(idToken, mobile?.e164)),
      mapError: (e) => switch ((e.response?.statusCode, _errorCode(e))) {
        (422, 'Auth.PhoneRequired') => const GooglePhoneRequiredFailure(),
        (409, _) => const AccountExistsFailure(),
        (400, 'Auth.GoogleTokenInvalid') => const GoogleTokenInvalidFailure(),
        _ => null,
      },
    );
  }

  @override
  Future<Result<String?>> linkGoogle(String idToken) => runApiCall(
    () => _remote.linkGoogle(idToken),
    mapError: (e) => switch ((e.response?.statusCode, _errorCode(e))) {
      (409, _) => const GoogleLinkedElsewhereFailure(),
      (400, 'Auth.GoogleTokenInvalid') => const GoogleTokenInvalidFailure(),
      _ => null,
    },
  );

  @override
  Future<Result<void>> unlinkGoogle() => runApiCall(
    _remote.unlinkGoogle,
    mapError: (e) => switch (e.response?.statusCode) {
      422 => const LastSignInMethodFailure(),
      _ => null,
    },
  );

  static String? _errorCode(DioException e) => errorCode(e.response?.data);

  Future<AuthSession> _startSession(OtpVerifyResponse response) async {
    await _session.signIn(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      onboarded: response.isOnboarded,
    );
    return AuthSession(isOnboarded: response.isOnboarded);
  }

  @override
  Future<Result<OtpChallenge>> requestOtp(MobileNumber mobile) {
    return runApiCall(() async {
      final response = await _remote.requestOtp(mobile.e164);
      return OtpChallenge(
        mobile: mobile,
        codeLength: 6,
        resendAfter: Duration(seconds: response.resendCooldownSeconds),
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
