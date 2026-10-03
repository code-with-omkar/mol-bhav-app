import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/auth/domain/entities/login_methods.dart';
import 'package:mol_bhav/features/auth/domain/usecases/password_auth.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/login_methods_cubit.dart';

class _MockGetLoginMethods extends Mock implements GetLoginMethods {}

void main() {
  late _MockGetLoginMethods getLoginMethods;

  setUp(() => getLoginMethods = _MockGetLoginMethods());

  blocTest<LoginMethodsCubit, LoginMethodsState>(
    'emits the server methods',
    setUp: () => when(() => getLoginMethods()).thenAnswer(
      (_) async => const Ok(LoginMethods(otp: true, password: true)),
    ),
    build: () => LoginMethodsCubit(getLoginMethods),
    act: (cubit) => cubit.load(),
    expect: () => const [
      // bloc always lets the first emit through, even when equal to the
      // initial state, so the loading state is observed before the answer.
      LoginMethodsState(),
      LoginMethodsState(
        methods: LoginMethods(otp: true, password: true),
        loading: false,
      ),
    ],
  );

  blocTest<LoginMethodsCubit, LoginMethodsState>(
    'falls back to password login when the server is unreachable',
    setUp: () =>
        when(() => getLoginMethods())
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: () => LoginMethodsCubit(getLoginMethods),
    act: (cubit) => cubit.load(),
    expect: () => const [
      LoginMethodsState(),
      LoginMethodsState(methods: LoginMethods.fallback, loading: false),
    ],
  );
}
