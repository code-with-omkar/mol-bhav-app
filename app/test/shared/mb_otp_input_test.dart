import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/shared/widgets/mb_otp_input.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('shows one digit per box, digits only, capped at length', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    await tester.pumpApp(
      Scaffold(
        body: MbOtpInput(
          controller: controller,
          semanticLabel: 'One-time password',
          onChanged: changes.add,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();

    expect(controller.text, '123456');
    expect(changes.last, '123456');
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('tapping the boxes focuses the hidden field', (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: MbOtpInput(
          controller: TextEditingController(),
          semanticLabel: 'One-time password',
          autofocus: false,
        ),
      ),
    );

    await tester.tap(
      find
          .descendant(
            of: find.byType(MbOtpInput),
            matching: find.byType(Container),
          )
          .first,
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });
}
