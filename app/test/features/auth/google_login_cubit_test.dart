import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/auth_session.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/usecases/password_auth.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/google_login_cubit.dart';

class _MockLoginWithGoogle extends Mock implements LoginWithGoogle {}

void main() {
  late _MockLoginWithGoogle login;
  const session = AuthSession(isOnboarded: false);
  final mobile = MobileNumber.tryParse('9876543210')!;

  setUpAll(() => registerFallbackValue(mobile));
  setUp(() => login = _MockLoginWithGoogle());

  GoogleLoginCubit build() => GoogleLoginCubit(login);

  blocTest<GoogleLoginCubit, GoogleLoginState>(
    'a linked Google account signs straight in',
    setUp: () =>
        when(() => login('tok')).thenAnswer((_) async => const Ok(session)),
    build: build,
    act: (cubit) => cubit.signIn('tok'),
    expect: () => const [
      GoogleLoginState(status: GoogleLoginStatus.submitting, idToken: 'tok'),
      GoogleLoginState(status: GoogleLoginStatus.success, session: session),
    ],
  );

  blocTest<GoogleLoginCubit, GoogleLoginState>(
    'a new Google account asks for the mobile number, then creates the account',
    setUp: () {
      when(() => login('tok'))
          .thenAnswer((_) async => const Err(GooglePhoneRequiredFailure()));
      when(
        () => login(
          'tok',
          mobile: any(named: 'mobile', that: isNotNull),
        ),
      ).thenAnswer((_) async => const Ok(session));
    },
    build: build,
    act: (cubit) async {
      await cubit.signIn('tok');
      await cubit.submitPhone('98765 43210');
    },
    skip: 1,
    expect: () => const [
      GoogleLoginState(status: GoogleLoginStatus.needsPhone, idToken: 'tok'),
      GoogleLoginState(status: GoogleLoginStatus.submitting, idToken: 'tok'),
      GoogleLoginState(status: GoogleLoginStatus.success, session: session),
    ],
    verify: (_) => verify(
      () => login(
        'tok',
        mobile: any(
          named: 'mobile',
          that: isA<MobileNumber>().having(
            (m) => m.digits,
            'digits',
            '9876543210',
          ),
        ),
      ),
    ).called(1),
  );

  blocTest<GoogleLoginCubit, GoogleLoginState>(
    'an invalid number stays on the mobile step without calling the API',
    build: build,
    seed: () => const GoogleLoginState(
      status: GoogleLoginStatus.needsPhone,
      idToken: 'tok',
    ),
    act: (cubit) => cubit.submitPhone('123'),
    expect: () => const [
      GoogleLoginState(
        status: GoogleLoginStatus.needsPhone,
        idToken: 'tok',
        showInvalidNumber: true,
      ),
    ],
    verify: (_) =>
        verifyNever(() => login(any(), mobile: any(named: 'mobile'))),
  );

  blocTest<GoogleLoginCubit, GoogleLoginState>(
    'a number that already has an account fails with AccountExists',
    setUp: () =>
        when(() => login('tok', mobile: any(named: 'mobile')))
            .thenAnswer((_) async => const Err(AccountExistsFailure())),
    build: build,
    seed: () => const GoogleLoginState(
      status: GoogleLoginStatus.needsPhone,
      idToken: 'tok',
    ),
    act: (cubit) => cubit.submitPhone('9876543210'),
    skip: 1,
    expect: () => const [
      GoogleLoginState(
        status: GoogleLoginStatus.failure,
        failure: AccountExistsFailure(),
      ),
    ],
  );
}
