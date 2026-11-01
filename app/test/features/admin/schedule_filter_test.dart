import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/presentation/admin_schedules_page.dart';

import '../../helpers/pump_app.dart';

const _item = IngestionScheduleItem(
  sourceId: 's1',
  sourceCode: 'agmarknet',
  sourceName: 'Agmarknet',
  sourceIsActive: true,
  categoryCode: 'agriculture',
  categoryName: 'Agriculture',
  isConfigured: true,
  isEnabled: true,
  frequency: ScheduleFrequency.daily,
  timeOfDay: '06:00',
);

final _options = FilterOptions(
  states: const ['Madhya Pradesh', 'Maharashtra'],
  commodities: const ['Onion', 'Tomato'],
  markets: const [
    FilterMarket(name: 'APMC Pune', state: 'Maharashtra'),
    FilterMarket(name: 'APMC Nagpur', state: 'Maharashtra'),
    FilterMarket(name: 'Indore', state: 'Madhya Pradesh'),
  ],
  refreshedAt: DateTime(2026, 10, 16),
);

void main() {
  group('parseFilterNames', () {
    test('splits on commas and new lines, trims, drops blanks', () {
      expect(parseFilterNames(' Maharashtra ,Goa\n\n Kerala,, '), [
        'Maharashtra',
        'Goa',
        'Kerala',
      ]);
    });
  });

  group('RunFilter', () {
    test('nothing selected = the whole feed', () {
      expect(const RunFilter().isEmpty, isTrue);
      expect(const RunFilter(states: ['Goa']).isEmpty, isFalse);
    });

    test('is sent as three lists', () {
      expect(
        const RunFilter(
          states: ['Maharashtra'],
          commodities: ['Onion'],
        ).toJson(),
        {
          'states': ['Maharashtra'],
          'commodities': ['Onion'],
          'markets': <String>[],
        },
      );
    });
  });

  group('FilterOptions', () {
    test('is empty until a full pull has run', () {
      expect(const FilterOptions().isEmpty, isTrue);
      expect(_options.isEmpty, isFalse);
    });

    test('markets follow the chosen states', () {
      expect(_options.marketsIn({}), ['APMC Pune', 'APMC Nagpur', 'Indore']);
      expect(_options.marketsIn({'Maharashtra'}), ['APMC Pune', 'APMC Nagpur']);
      expect(_options.marketsIn({'Madhya Pradesh'}), ['Indore']);
    });
  });

  test('a schedule never carries a filter: scheduled runs pull everything', () {
    expect(_item.toInput().toJson().keys, isNot(contains('states')));
  });

  group('Run now sheet', () {
    Future<void> pump(
      WidgetTester tester,
      Future<Result<FilterOptions>> options,
      ValueChanged<RunFilter> onRun,
    ) => tester.pumpApp(
      Scaffold(
        body: RunNowSheet(item: _item, options: options, onRun: onRun),
      ),
    );

    Future<void> run(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Run now'));
      await tester.tap(find.text('Run now'));
      await tester.pump();
    }

    testWidgets('shows three dropdowns, all on All', (tester) async {
      await pump(tester, Future.value(Ok(_options)), (_) {});
      await tester.pumpAndSettle();

      expect(find.text('States'), findsOneWidget);
      expect(find.text('Commodities'), findsOneWidget);
      expect(find.text('Markets'), findsOneWidget);
      expect(find.text('All'), findsNWidgets(3));
    });

    testWidgets('picking a state from the list filters the run', (
      tester,
    ) async {
      RunFilter? ran;
      await pump(tester, Future.value(Ok(_options)), (f) => ran = f);
      await tester.pumpAndSettle();

      await tester.tap(find.text('All').at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maharashtra'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Maharashtra'), findsOneWidget); // now the field summary

      await run(tester);

      expect(ran?.states, ['Maharashtra']);
      expect(ran?.commodities, isEmpty);
      expect(ran?.markets, isEmpty);
    });

    testWidgets('the markets list only offers the chosen states\' markets', (
      tester,
    ) async {
      await pump(tester, Future.value(Ok(_options)), (_) {});
      await tester.pumpAndSettle();

      await tester.tap(find.text('All').at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Madhya Pradesh'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All').at(1));
      await tester.pumpAndSettle();

      expect(find.text('Indore'), findsOneWidget);
      expect(find.text('APMC Pune'), findsNothing);
    });

    testWidgets('the list can be searched', (tester) async {
      await pump(tester, Future.value(Ok(_options)), (_) {});
      await tester.pumpAndSettle();

      await tester.tap(find.text('All').at(1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'tom');
      await tester.pump();

      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Onion'), findsNothing);
    });

    testWidgets('before any full pull the lists are disabled and a full run '
        'is still possible', (tester) async {
      RunFilter? ran;
      await pump(
        tester,
        Future.value(const Ok(FilterOptions())),
        (f) => ran = f,
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('lists fill after the first full pull'),
        findsOneWidget,
      );

      await tester.tap(find.text('States'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsNothing); // the picker did not open

      await run(tester);
      expect(ran?.isEmpty, isTrue);
    });

    testWidgets('a failed load says so and still allows a full run', (
      tester,
    ) async {
      RunFilter? ran;
      await pump(
        tester,
        Future.value(const Err(NetworkFailure())),
        (f) => ran = f,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Couldn\'t load the choices'), findsOneWidget);

      await run(tester);
      expect(ran?.isEmpty, isTrue);
    });

    testWidgets('says that only this run is filtered', (tester) async {
      await pump(tester, Future.value(Ok(_options)), (_) {});
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Scheduled runs always pull everything'),
        findsOneWidget,
      );
    });
  });
}
