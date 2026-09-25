import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/features/auth/domain/auth_failures.dart';
import 'package:mol_bhav/features/auth/domain/entities/mobile_number.dart';
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart';
import 'package:mol_bhav/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:mol_bhav/features/auth/presentation/pages/otp_page.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockOtpCubit extends MockCubit<OtpState> implements OtpCubit {}

void main() {
  late _MockOtpCubit cubit;
  final challenge = OtpChallenge(
    mobile: MobileNumber.tryParse('9876543210')!,
    codeLength: 6,
    resendAfter: const Duration(seconds: 30),
  );

  setUp(() => cubit = _MockOtpCubit());

  Future<void> pump(WidgetTester tester, OtpState state) {
    when(() => cubit.state).thenReturn(state);
    return tester.pumpApp(
      BlocProvider<OtpCubit>.value(value: cubit, child: const OtpPage()),
    );
  }

  MbButton verifyButton(WidgetTester tester) => tester.widget<MbButton>(
    find.widgetWithText(MbButton, 'Verify & Continue'),
  );

  testWidgets('shows the number, countdown and a disabled verify', (
    tester,
  ) async {
    await pump(tester, OtpState(challenge: challenge, secondsLeft: 24));

    expect(find.text('Enter the OTP'), findsOneWidget);
    expect(find.textContaining('Sent to +91 98765 43210'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Resend OTP in 00:24'), findsOneWidget);
    expect(verifyButton(tester).onPressed, isNull);
  });

  testWidgets('enables verify once the code is complete', (tester) async {
    await pump(
      tester,
      OtpState(challenge: challenge, secondsLeft: 24, code: '123456'),
    );

    expect(verifyButton(tester).onPressed, isNotNull);
  });

  testWidgets('offers resend when the countdown ends', (tester) async {
    when(() => cubit.resend()).thenAnswer((_) async {});
    await pump(tester, OtpState(challenge: challenge, secondsLeft: 0));

    await tester.tap(find.text('Resend OTP'));

    verify(() => cubit.resend()).called(1);
  });

  testWidgets('shows the invalid-code message', (tester) async {
    await pump(
      tester,
      OtpState(
        challenge: challenge,
        secondsLeft: 10,
        code: '000000',
        status: OtpStatus.failure,
        failure: const InvalidOtpFailure(),
      ),
    );

    expect(find.text('The OTP is incorrect or has expired.'), findsOneWidget);
  });
}
