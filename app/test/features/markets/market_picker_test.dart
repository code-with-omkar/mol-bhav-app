import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/features/markets/domain/markets_entities.dart';
import 'package:mol_bhav/features/markets/presentation/market_picker.dart';

import '../../helpers/pump_app.dart';

List<MarketRef> _markets(int n) => [
  for (var i = 1; i <= n; i++) MarketRef(id: 'm$i', name: 'Market $i'),
];

void main() {
  Future<void> pump(WidgetTester tester, int count) => tester.pumpApp(
    Scaffold(
      body: MarketPicker(
        markets: _markets(count),
        selected: const {'m1'},
        onChanged: (_) {},
      ),
    ),
  );

  // The picker used to turn into a row of chips for products with few
  // markets, so changing the product made the control change shape.
  for (final count in [2, 6, 7, 23]) {
    testWidgets('is one field that opens a list with $count markets', (
      tester,
    ) async {
      await pump(tester, count);

      expect(find.text('1 of $count markets'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  }

  testWidgets('opens the searchable list when tapped', (tester) async {
    await pump(tester, 3);

    await tester.tap(find.text('1 of 3 markets'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckboxListTile), findsNWidgets(3));
  });
}
