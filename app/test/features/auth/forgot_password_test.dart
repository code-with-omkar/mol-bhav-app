import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/router/app_routes.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/password_reset.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/pages/forgot_password_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements PasswordResetRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.requestCode(any()))
        .thenAnswer((_) async => const Ok<void>(null));
    when(
      () => repository.resetPassword(
        phoneNumber: any(named: 'phoneNumber'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Ok<void>(null));
  });

  Future<void> pumpPage(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: AppRoutes.forgotPassword,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('login-route')),
          routes: [
            GoRoute(
              path: 'forgot',
              builder: (_, _) => BlocProvider(
                create: (_) => ForgotPasswordCubit(repository),
                child: const ForgotPasswordPage(),
              ),
            ),
          ],
        ),
      ],
    );
    return tester.pumpRouterApp(router);
  }

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );

  Future<void> askForCode(WidgetTester tester) async {
    await tester.enterText(field('forgot-mobile'), '9876543210');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
  }

  testWidgets('an incomplete number sends nothing', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(field('forgot-mobile'), '98765');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.requestCode(any()));
    expect(field('forgot-code'), findsNothing);
  });

  testWidgets('code then new password returns to login', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();
    await askForCode(tester);

    verify(() => repository.requestCode('+919876543210')).called(1);

    await tester.enterText(field('forgot-code'), '123456');
    await tester.enterText(field('forgot-password'), 'Secret@12345');
    await tester.enterText(field('forgot-confirm'), 'Secret@12345');
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();

    verify(
      () => repository.resetPassword(
        phoneNumber: '+919876543210',
        code: '123456',
        newPassword: 'Secret@12345',
      ),
    ).called(1);
    expect(find.text('login-route'), findsOneWidget);
  });

  testWidgets('passwords that differ are not sent', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();
    await askForCode(tester);

    await tester.enterText(field('forgot-code'), '123456');
    await tester.enterText(field('forgot-password'), 'Secret@12345');
    await tester.enterText(field('forgot-confirm'), 'Secret@12346');
    await tester.ensureVisible(find.text('Set new password'));
    await tester.tap(find.text('Set new password'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.resetPassword(
        phoneNumber: any(named: 'phoneNumber'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });

  test('a rejected reset keeps the second step', () async {
    when(
      () => repository.resetPassword(
        phoneNumber: any(named: 'phoneNumber'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Err<void>(NetworkFailure()));
    final cubit = ForgotPasswordCubit(repository);
    addTearDown(cubit.close);
    await cubit.sendCode(MobileNumber.tryParse('9876543210')!);

    final failure = await cubit.reset(
      code: '000000',
      newPassword: 'Secret@12345',
    );

    expect(failure, const NetworkFailure());
    expect(cubit.state.sentTo, isNotNull);
    expect(cubit.state.busy, isFalse);
  });
}
