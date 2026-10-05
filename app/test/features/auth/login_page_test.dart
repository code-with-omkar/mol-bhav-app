import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/locale/app_language.dart';
import 'package:mol_bhav/core/locale/locale_cubit.dart';
import 'package:mol_bhav/core/router/app_routes.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/login_methods.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart';
import 'package:mol_bhav/features/auth/domain/usecases/password_auth.dart';
import 'package:mol_bhav/features/auth/domain/usecases/request_otp.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/google_login_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/login_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/login_methods_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/password_login_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/pages/login_page.dart';
import 'package:mol_bhav/shared/widgets/mb_wordmark.dart';

import '../../helpers/pump_app.dart';

class _MockRequestOtp extends Mock implements RequestOtp {}

class _MockLocaleCubit extends MockCubit<AppLanguage> implements LocaleCubit {}

class _MockLoginMethodsCubit extends MockCubit<LoginMethodsState>
    implements LoginMethodsCubit {}

class _MockLoginWithPassword extends Mock implements LoginWithPassword {}

class _MockRegisterWithPassword extends Mock implements RegisterWithPassword {}

class _MockLoginWithGoogle extends Mock implements LoginWithGoogle {}

const _otpOnly = LoginMethodsState(
  methods: LoginMethods(otp: true, password: false),
  loading: false,
);
const _passwordOnly = LoginMethodsState(
  methods: LoginMethods(otp: false, password: true),
  loading: false,
);
const _both = LoginMethodsState(
  methods: LoginMethods(otp: true, password: true),
  loading: false,
);

void main() {
  late _MockRequestOtp requestOtp;
  late _MockLocaleCubit localeCubit;
  late _MockLoginMethodsCubit methodsCubit;
  late _MockLoginWithPassword loginWithPassword;
  late _MockRegisterWithPassword registerWithPassword;
  Object? pushedExtra;

  final mobile = MobileNumber.tryParse('9876543210')!;

  setUpAll(() => registerFallbackValue(mobile));

  setUp(() {
    requestOtp = _MockRequestOtp();
    localeCubit = _MockLocaleCubit();
    methodsCubit = _MockLoginMethodsCubit();
    loginWithPassword = _MockLoginWithPassword();
    registerWithPassword = _MockRegisterWithPassword();
    when(() => methodsCubit.state).thenReturn(_otpOnly);
    pushedExtra = null;
    when(() => localeCubit.state).thenReturn(AppLanguage.english);
    when(() => localeCubit.select(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(AppLanguage.english));

  Future<void> pumpLogin(
    WidgetTester tester, {
    LoginMethodsState methods = _otpOnly,
  }) {
    when(() => methodsCubit.state).thenReturn(methods);
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => LoginCubit(requestOtp)),
              BlocProvider<LoginMethodsCubit>.value(value: methodsCubit),
              BlocProvider(
                create: (_) =>
                    PasswordLoginCubit(loginWithPassword, registerWithPassword),
              ),
              BlocProvider<LocaleCubit>.value(value: localeCubit),
              BlocProvider(
                create: (_) => GoogleLoginCubit(_MockLoginWithGoogle()),
              ),
            ],
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.verifyOtp,
          builder: (_, state) {
            pushedExtra = state.extra;
            return const Scaffold(body: Text('otp-route'));
          },
        ),
      ],
    );
    return tester.pumpRouterApp(router);
  }

  testWidgets('renders the sample page content', (tester) async {
    await pumpLogin(tester);

    expect(find.byType(MbWordmark), findsOneWidget);
    expect(find.text('Log in with your mobile'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    for (final language in AppLanguage.values) {
      expect(find.text(language.nativeName), findsOneWidget);
    }
    expect(
      find.text('Your number is only used to sign you in.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a validation error for an invalid number', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
    verifyNever(() => requestOtp(any()));
  });

  testWidgets('requests an OTP and opens the verify step', (tester) async {
    final challenge = OtpChallenge(
      mobile: mobile,
      codeLength: 6,
      resendAfter: const Duration(seconds: 30),
    );
    when(() => requestOtp(any())).thenAnswer((_) async => Ok(challenge));
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField), '9876543210');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '98765 43210',
    );
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('otp-route'), findsOneWidget);
    expect(pushedExtra, challenge);
  });

  testWidgets('shows a snackbar when the request fails', (tester) async {
    when(() => requestOtp(any()))
        .thenAnswer((_) async => const Err(NetworkFailure()));
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No internet connection. Check your network and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('selecting a language chip switches the app language', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('मराठी'));
    await tester.pump();

    verify(() => localeCubit.select(AppLanguage.marathi)).called(1);
  });

  group('password login', () {
    testWidgets('shows only the password card when OTP is off', (tester) async {
      await pumpLogin(tester, methods: _passwordOnly);

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);
      expect(find.text('Log in with OTP instead'), findsNothing);
    });

    testWidgets('switches to OTP and back when both are enabled', (
      tester,
    ) async {
      // The page (language picker + password card + switch link) is taller
      // than the default 800x600 surface; give it room so the link is hittable.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpLogin(tester, methods: _both);

      await tester.tap(find.text('Log in with OTP instead'));
      await tester.pump();
      expect(find.text('Send OTP'), findsOneWidget);

      await tester.tap(find.text('Log in with password instead'));
      await tester.pump();
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('validates before calling the API', (tester) async {
      await pumpLogin(tester, methods: _passwordOnly);

      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );
      expect(find.text('Enter your password.'), findsOneWidget);
      verifyNever(() => loginWithPassword(any(), any()));
    });

    testWidgets('shows the wrong-credentials message', (tester) async {
      when(() => loginWithPassword(any(), any()))
          .thenAnswer((_) async => const Err(InvalidCredentialsFailure()));
      await pumpLogin(tester, methods: _passwordOnly);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '9876543210');
      await tester.enterText(fields.at(1), 'kanda2026');
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Incorrect mobile number or password.'), findsOneWidget);
      verify(() => loginWithPassword(mobile, 'kanda2026')).called(1);
    });

    testWidgets('create account shows the confirm field', (tester) async {
      await pumpLogin(tester, methods: _passwordOnly);

      await tester.tap(find.text('New to MolBhav? Create an account'));
      await tester.pump();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });
  });
}
