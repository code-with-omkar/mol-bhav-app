import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/storage/saved_credentials_store.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/auth_session.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/usecases/password_auth.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/password_login_cubit.dart';

class _MockLogin extends Mock implements LoginWithPassword {}

class _MockRegister extends Mock implements RegisterWithPassword {}

class _MockStore extends Mock implements SavedCredentialsStore {}

void main() {
  late _MockLogin login;
  late _MockRegister register;
  final mobile = MobileNumber.tryParse('9876543210')!;
  const session = AuthSession(isOnboarded: true);

  setUpAll(() => registerFallbackValue(mobile));
  setUp(() {
    login = _MockLogin();
    register = _MockRegister();
  });

  PasswordLoginCubit build() => PasswordLoginCubit(login, register);

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'flags an invalid number and an empty password without calling the API',
    build: build,
    act: (cubit) => cubit.submit(),
    expect: () => const [
      PasswordLoginState(
        showInvalidNumber: true,
        passwordIssue: PasswordIssue.empty,
      ),
    ],
    verify: (_) => verifyNever(() => login(any(), any())),
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'logs in and emits success with the session',
    setUp: () =>
        when(() => login(any(), any()))
            .thenAnswer((_) async => const Ok(session)),
    build: build,
    seed: () =>
        const PasswordLoginState(mobile: '98765 43210', password: 'kanda2026'),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      PasswordLoginState(
        mobile: '98765 43210',
        password: 'kanda2026',
        status: PasswordLoginStatus.submitting,
      ),
      PasswordLoginState(
        mobile: '98765 43210',
        status: PasswordLoginStatus.success,
        session: session,
      ),
    ],
    verify: (_) => verify(() => login(mobile, 'kanda2026')).called(1),
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'keeps the input and reports wrong credentials',
    setUp: () =>
        when(() => login(any(), any()))
            .thenAnswer((_) async => const Err(InvalidCredentialsFailure())),
    build: build,
    seed: () =>
        const PasswordLoginState(mobile: '9876543210', password: 'wrong'),
    act: (cubit) => cubit.submit(),
    skip: 1,
    expect: () => const [
      PasswordLoginState(
        mobile: '9876543210',
        password: 'wrong',
        status: PasswordLoginStatus.failure,
        failure: InvalidCredentialsFailure(),
      ),
    ],
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'register rejects a weak password locally',
    build: build,
    seed: () => const PasswordLoginState(
      mode: PasswordLoginMode.register,
      mobile: '9876543210',
      password: 'onlyletters',
      confirmPassword: 'onlyletters',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      PasswordLoginState(
        mode: PasswordLoginMode.register,
        mobile: '9876543210',
        password: 'onlyletters',
        confirmPassword: 'onlyletters',
        passwordIssue: PasswordIssue.tooWeak,
      ),
    ],
    verify: (_) => verifyNever(() => register(any(), any())),
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'register rejects a mismatched confirmation locally',
    build: build,
    seed: () => const PasswordLoginState(
      mode: PasswordLoginMode.register,
      mobile: '9876543210',
      password: 'kanda2026',
      confirmPassword: 'kanda2027',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      PasswordLoginState(
        mode: PasswordLoginMode.register,
        mobile: '9876543210',
        password: 'kanda2026',
        confirmPassword: 'kanda2027',
        passwordIssue: PasswordIssue.mismatch,
      ),
    ],
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'register calls the register use case, not login',
    setUp: () =>
        when(() => register(any(), any()))
            .thenAnswer((_) async => const Ok(AuthSession(isOnboarded: false))),
    build: build,
    seed: () => const PasswordLoginState(
      mode: PasswordLoginMode.register,
      mobile: '9876543210',
      password: 'kanda2026',
      confirmPassword: 'kanda2026',
    ),
    act: (cubit) => cubit.submit(),
    skip: 1,
    expect: () => const [
      PasswordLoginState(
        mode: PasswordLoginMode.register,
        mobile: '9876543210',
        status: PasswordLoginStatus.success,
        session: AuthSession(isOnboarded: false),
      ),
    ],
    verify: (_) {
      verify(() => register(mobile, 'kanda2026')).called(1);
      verifyNever(() => login(any(), any()));
    },
  );

  blocTest<PasswordLoginCubit, PasswordLoginState>(
    'toggling mode keeps the number and password, clears the confirmation',
    build: build,
    seed: () => const PasswordLoginState(
      mode: PasswordLoginMode.register,
      mobile: '9876543210',
      password: 'kanda2026',
      confirmPassword: 'x',
      passwordIssue: PasswordIssue.mismatch,
    ),
    act: (cubit) => cubit.toggleMode(),
    expect: () => const [
      PasswordLoginState(mobile: '9876543210', password: 'kanda2026'),
    ],
  );

  group('Save password', () {
    late _MockStore store;
    const saved = SavedCredentials(
      mobileDigits: '9876543210',
      password: 'kanda2026',
    );

    setUpAll(
      () => registerFallbackValue(
        const SavedCredentials(mobileDigits: '', password: ''),
      ),
    );

    setUp(() {
      store = _MockStore();
      when(() => store.isSupported).thenReturn(true);
      when(() => store.readEnabled()).thenAnswer((_) async => true);
      when(() => store.read()).thenAnswer((_) async => saved);
      when(() => store.save(any())).thenAnswer((_) async {});
      when(() => store.setEnabled(any())).thenAnswer((_) async {});
      when(() => store.forget()).thenAnswer((_) async {});
    });

    PasswordLoginCubit withStore() =>
        PasswordLoginCubit(login, register, savedCredentials: store);

    blocTest<PasswordLoginCubit, PasswordLoginState>(
      'loadSaved shows the switch (on) and prefills the saved login',
      build: withStore,
      act: (cubit) => cubit.loadSaved(),
      expect: () => const [
        PasswordLoginState(
          mobile: '9876543210',
          password: 'kanda2026',
          canSavePassword: true,
          prefillSeq: 1,
        ),
      ],
    );

    blocTest<PasswordLoginCubit, PasswordLoginState>(
      'loadSaved keeps the switch hidden where saving is unsupported (web)',
      setUp: () => when(() => store.isSupported).thenReturn(false),
      build: withStore,
      act: (cubit) => cubit.loadSaved(),
      expect: () => const <PasswordLoginState>[],
    );

    blocTest<PasswordLoginCubit, PasswordLoginState>(
      'a successful login saves the credentials while the switch is on',
      setUp: () =>
          when(() => login(any(), any()))
              .thenAnswer((_) async => const Ok(session)),
      build: withStore,
      seed: () => const PasswordLoginState(
        mobile: '98765 43210',
        password: 'kanda2026',
        canSavePassword: true,
      ),
      act: (cubit) => cubit.submit(),
      skip: 1,
      expect: () => const [
        PasswordLoginState(
          mobile: '98765 43210',
          status: PasswordLoginStatus.success,
          session: session,
          canSavePassword: true,
        ),
      ],
      verify: (_) => verify(
        () => store.save(
          any(
            that: isA<SavedCredentials>()
                .having((c) => c.mobileDigits, 'mobile', '9876543210')
                .having((c) => c.password, 'password', 'kanda2026'),
          ),
        ),
      ).called(1),
    );

    blocTest<PasswordLoginCubit, PasswordLoginState>(
      'with the switch off nothing is saved, and switching off forgets',
      setUp: () =>
          when(() => login(any(), any()))
              .thenAnswer((_) async => const Ok(session)),
      build: withStore,
      seed: () => const PasswordLoginState(
        mobile: '98765 43210',
        password: 'kanda2026',
        canSavePassword: true,
      ),
      act: (cubit) async {
        await cubit.savePasswordChanged(false);
        await cubit.submit();
      },
      verify: (_) {
        verify(() => store.setEnabled(false)).called(1);
        verifyNever(() => store.save(any()));
      },
    );

    blocTest<PasswordLoginCubit, PasswordLoginState>(
      'a rejected saved password is forgotten',
      setUp: () =>
          when(() => login(any(), any()))
              .thenAnswer((_) async => const Err(InvalidCredentialsFailure())),
      build: withStore,
      seed: () => const PasswordLoginState(
        mobile: '9876543210',
        password: 'kanda2026',
        canSavePassword: true,
      ),
      act: (cubit) => cubit.submit(),
      verify: (_) => verify(() => store.forget()).called(1),
    );
  });
}
