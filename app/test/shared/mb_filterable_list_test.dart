import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/shared/widgets/mb_filterable_list.dart';

import '../helpers/pump_app.dart';

void main() {
  const markets = [
    ('Pune', 30),
    ('Nashik', 10),
    ('Nagpur', 20),
    ('Satara', 40),
  ];

  Future<void> pump(
    WidgetTester tester, [
    List<(String, int)> items = markets,
  ]) {
    return tester.pumpApp(
      Scaffold(
        body: SingleChildScrollView(
          child: MbFilterableList<(String, int)>(
            items: items,
            searchText: (m) => m.$1,
            sorts: [
              MbSort('Cheapest', (a, b) => a.$2.compareTo(b.$2)),
              MbSort('Name', (a, b) => a.$1.compareTo(b.$1)),
            ],
            filters: [MbFilter('Under 25', (m) => m.$2 < 25)],
            builder: (_, visible) =>
                Text(visible.map((m) => m.$1).join(','), key: const Key('out')),
          ),
        ),
      ),
    );
  }

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('out'))).data!;

  testWidgets('starts in the first order', (tester) async {
    await pump(tester);

    expect(shown(tester), 'Nashik,Nagpur,Pune,Satara');
  });

  testWidgets('searches as you type and says when nothing matches', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(EditableText), 'na');
    await tester.pump();
    expect(shown(tester), 'Nashik,Nagpur');

    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pump();
    expect(find.byKey(const Key('out')), findsNothing);
    expect(find.text('Nothing matches your search.'), findsOneWidget);
  });

  testWidgets('filters and sorts', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Under 25'));
    await tester.pump();
    expect(shown(tester), 'Nashik,Nagpur');

    await tester.tap(find.byKey(const ValueKey('list-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();
    expect(shown(tester), 'Nagpur,Nashik');
  });

  testWidgets('a short list has no controls', (tester) async {
    await pump(tester, markets.sublist(0, 2));

    expect(find.byType(EditableText), findsNothing);
    expect(shown(tester), 'Pune,Nashik');
  });
}
