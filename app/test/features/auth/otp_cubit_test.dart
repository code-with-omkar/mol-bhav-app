import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/countdown.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/auth_session.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart';
import 'package:mol_bhav/features/auth/domain/usecases/request_otp.dart';
import 'package:mol_bhav/features/auth/domain/usecases/verify_otp.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/otp_cubit.dart';

class _MockVerifyOtp extends Mock implements VerifyOtp {}

class _MockRequestOtp extends Mock implements RequestOtp {}

class _MockCountdown extends Mock implements Countdown {}

void main() {
  late _MockVerifyOtp verifyOtp;
  late _MockRequestOtp requestOtp;
  late _MockCountdown countdown;
  late StreamController<int> ticks;
  final mobile = MobileNumber.tryParse('9876543210')!;
  final challenge = OtpChallenge(
    mobile: mobile,
    codeLength: 6,
    resendAfter: const Duration(seconds: 30),
  );

  setUpAll(() => registerFallbackValue(mobile));

  setUp(() {
    verifyOtp = _MockVerifyOtp();
    requestOtp = _MockRequestOtp();
    countdown = _MockCountdown();
    ticks = StreamController<int>.broadcast();
    when(() => countdown.start(any())).thenAnswer((_) => ticks.stream);
  });

  tearDown(() => ticks.close());

  OtpCubit build() => OtpCubit(challenge, verifyOtp, requestOtp, countdown);

  void stubVerify(Result<AuthSession> result) {
    when(
      () => verifyOtp(
        mobile: any(named: 'mobile'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('starts with the full resend delay and no code', () async {
    final cubit = build();
    expect(cubit.state.secondsLeft, 30);
    expect(cubit.state.isComplete, isFalse);
    expect(cubit.state.canResend, isFalse);
    await cubit.close();
  });

  blocTest<OtpCubit, OtpState>(
    'counts down from the ticker',
    build: build,
    act: (_) => ticks
      ..add(29)
      ..add(0),
    expect: () => [
      OtpState(challenge: challenge, secondsLeft: 29),
      OtpState(challenge: challenge, secondsLeft: 0),
    ],
  );

  blocTest<OtpCubit, OtpState>(
    'does not verify an incomplete code',
    build: build,
    act: (cubit) => cubit
      ..codeChanged('123')
      ..verify(),
    expect: () => [
      OtpState(challenge: challenge, secondsLeft: 30, code: '123'),
    ],
    verify: (_) => verifyNever(
      () => verifyOtp(
        mobile: any(named: 'mobile'),
        code: any(named: 'code'),
      ),
    ),
  );

  blocTest<OtpCubit, OtpState>(
    'emits verified with the session',
    setUp: () => stubVerify(const Ok(AuthSession(isOnboarded: false))),
    build: build,
    seed: () => OtpState(challenge: challenge, secondsLeft: 30, code: '123456'),
    act: (cubit) => cubit.verify(),
    expect: () => [
      OtpState(
        challenge: challenge,
        secondsLeft: 30,
        code: '123456',
        status: OtpStatus.verifying,
      ),
      OtpState(
        challenge: challenge,
        secondsLeft: 30,
        code: '123456',
        status: OtpStatus.verified,
        session: const AuthSession(isOnboarded: false),
      ),
    ],
    verify: (_) =>
        verify(() => verifyOtp(mobile: mobile, code: '123456')).called(1),
  );

  blocTest<OtpCubit, OtpState>(
    'flags an invalid code, and editing clears it',
    setUp: () => stubVerify(const Err(InvalidOtpFailure())),
    build: build,
    seed: () => OtpState(challenge: challenge, secondsLeft: 30, code: '000000'),
    act: (cubit) async {
      await cubit.verify();
      expect(cubit.state.isCodeInvalid, isTrue);
      cubit.codeChanged('00000');
    },
    skip: 2,
    expect: () => [
      OtpState(challenge: challenge, secondsLeft: 30, code: '00000'),
    ],
  );

  blocTest<OtpCubit, OtpState>(
    'resends once the countdown ends and restarts it',
    setUp: () =>
        when(() => requestOtp(any())).thenAnswer((_) async => Ok(challenge)),
    build: build,
    seed: () => OtpState(challenge: challenge, secondsLeft: 0, code: '12'),
    act: (cubit) => cubit.resend(),
    expect: () => [
      OtpState(
        challenge: challenge,
        secondsLeft: 0,
        status: OtpStatus.resending,
      ),
      OtpState(challenge: challenge, secondsLeft: 30, status: OtpStatus.resent),
    ],
    verify: (_) {
      verify(() => requestOtp(mobile)).called(1);
      // Once on creation, once after the resend.
      verify(() => countdown.start(any())).called(2);
    },
  );

  blocTest<OtpCubit, OtpState>(
    'ignores resend while the countdown is running',
    build: build,
    act: (cubit) => cubit.resend(),
    expect: () => const <OtpState>[],
    verify: (_) => verifyNever(() => requestOtp(any())),
  );

  blocTest<OtpCubit, OtpState>(
    'surfaces a resend failure',
    setUp: () =>
        when(() => requestOtp(any()))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    seed: () => OtpState(challenge: challenge, secondsLeft: 0),
    act: (cubit) => cubit.resend(),
    expect: () => [
      OtpState(
        challenge: challenge,
        secondsLeft: 0,
        status: OtpStatus.resending,
      ),
      OtpState(
        challenge: challenge,
        secondsLeft: 0,
        status: OtpStatus.failure,
        failure: const NetworkFailure(),
      ),
    ],
  );
}
