import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart';
import 'package:mol_bhav/features/auth/domain/usecases/request_otp.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/login_cubit.dart';

class _MockRequestOtp extends Mock implements RequestOtp {}

void main() {
  late _MockRequestOtp requestOtp;
  final mobile = MobileNumber.tryParse('9876543210')!;
  final challenge = OtpChallenge(
    mobile: mobile,
    codeLength: 6,
    resendAfter: const Duration(seconds: 30),
  );

  setUpAll(() => registerFallbackValue(mobile));
  setUp(() => requestOtp = _MockRequestOtp());

  blocTest<LoginCubit, LoginState>(
    'flags an invalid number without calling the API',
    build: () => LoginCubit(requestOtp),
    act: (cubit) => cubit
      ..mobileChanged('12345')
      ..submit(),
    expect: () => const [
      LoginState(input: '12345'),
      LoginState(input: '12345', showInvalidNumber: true),
    ],
    verify: (_) => verifyNever(() => requestOtp(any())),
  );

  blocTest<LoginCubit, LoginState>(
    'editing clears the invalid-number error',
    build: () => LoginCubit(requestOtp),
    seed: () => const LoginState(input: '1', showInvalidNumber: true),
    act: (cubit) => cubit.mobileChanged('98'),
    expect: () => const [LoginState(input: '98')],
  );

  blocTest<LoginCubit, LoginState>(
    'emits codeSent with the challenge on success',
    setUp: () =>
        when(() => requestOtp(any())).thenAnswer((_) async => Ok(challenge)),
    build: () => LoginCubit(requestOtp),
    seed: () => const LoginState(input: '98765 43210'),
    act: (cubit) => cubit.submit(),
    expect: () => [
      const LoginState(input: '98765 43210', status: LoginStatus.submitting),
      LoginState(
        input: '98765 43210',
        status: LoginStatus.codeSent,
        challenge: challenge,
      ),
    ],
    verify: (_) => verify(() => requestOtp(mobile)).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'emits failure when the request fails',
    setUp: () =>
        when(() => requestOtp(any()))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => LoginCubit(requestOtp),
    seed: () => const LoginState(input: '98765 43210'),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      LoginState(input: '98765 43210', status: LoginStatus.submitting),
      LoginState(
        input: '98765 43210',
        status: LoginStatus.failure,
        failure: NetworkFailure(),
      ),
    ],
  );
}
