import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mol_bhav/features/auth/data/models/auth_models.dart';
import 'package:mol_bhav/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/auth_session.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockSession extends Mock implements SessionManager {}

DioException _badResponse(int status) {
  final options = RequestOptions(path: '/auth/otp/verify');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status),
  );
}

void main() {
  late _MockRemote remote;
  late _MockSession tokens;
  late AuthRepositoryImpl repository;
  final mobile = MobileNumber.tryParse('9876543210')!;

  setUp(() {
    remote = _MockRemote();
    tokens = _MockSession();
    repository = AuthRepositoryImpl(remote, tokens);
  });

  test('requestOtp sends E.164 and returns the challenge', () async {
    when(() => remote.requestOtp(any())).thenAnswer(
      (_) async =>
          const OtpRequestResponse(otpLength: 6, resendAfterSeconds: 30),
    );

    final result = await repository.requestOtp(mobile);

    verify(() => remote.requestOtp('+919876543210')).called(1);
    expect(
      result.fold((_) => null, (c) => c),
      OtpChallenge(
        mobile: mobile,
        codeLength: 6,
        resendAfter: const Duration(seconds: 30),
      ),
    );
  });

  test('verifyOtp stores tokens and returns the session', () async {
    when(() => remote.verifyOtp(any(), any())).thenAnswer(
      (_) async => const OtpVerifyResponse(
        accessToken: 'a',
        refreshToken: 'r',
        isOnboarded: true,
      ),
    );
    when(
      () => tokens.signIn(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
        onboarded: any(named: 'onboarded'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.verifyOtp(mobile: mobile, code: '123456');

    expect(
      result.fold((_) => null, (s) => s),
      const AuthSession(isOnboarded: true),
    );
    verify(
      () => tokens.signIn(accessToken: 'a', refreshToken: 'r', onboarded: true),
    ).called(1);
  });

  for (final status in [400, 401, 422]) {
    test('verifyOtp maps $status to InvalidOtpFailure', () async {
      when(() => remote.verifyOtp(any(), any()))
          .thenThrow(_badResponse(status));

      final result = await repository.verifyOtp(mobile: mobile, code: '000000');

      expect(result.fold((f) => f, (_) => null), const InvalidOtpFailure());
      verifyNever(
        () => tokens.signIn(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
          onboarded: any(named: 'onboarded'),
        ),
      );
    });
  }

  test('verifyOtp keeps the default mapping for server errors', () async {
    when(() => remote.verifyOtp(any(), any())).thenThrow(_badResponse(503));

    final result = await repository.verifyOtp(mobile: mobile, code: '000000');

    expect(
      result.fold((f) => f, (_) => null),
      const ServerFailure(statusCode: 503),
    );
  });

  test('models parse the documented payloads', () {
    final request = OtpRequestResponse.fromJson({
      'otpLength': 6,
      'resendAfterSeconds': 30,
    });
    final verified = OtpVerifyResponse.fromJson({
      'accessToken': 'a',
      'refreshToken': 'r',
      'isOnboarded': false,
    });
    expect(request.otpLength, 6);
    expect(request.resendAfterSeconds, 30);
    expect(verified.isOnboarded, isFalse);
  });
}
