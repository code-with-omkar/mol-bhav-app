import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_markets_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/domain/admin_markets.dart';
import 'package:mol_bhav/features/admin/presentation/admin_markets_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_markets_page.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockIngestion extends Mock implements AdminIngestionRepository {}

class _MockMarkets extends Mock implements AdminMarketsRepository {}

const _agmarknet = IngestionScheduleItem(
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
  states: const ['Gujarat', 'Maharashtra'],
  commodities: const ['Onion'],
  markets: const [
    FilterMarket(name: 'Rajkot', state: 'Gujarat'),
    FilterMarket(name: 'Anand', state: 'Gujarat'),
    FilterMarket(name: 'APMC Pune', state: 'Maharashtra'),
  ],
  refreshedAt: DateTime(2026, 11, 1),
);

void main() {
  late _MockIngestion ingestion;
  late _MockMarkets markets;

  setUp(() {
    ingestion = _MockIngestion();
    markets = _MockMarkets();
    when(() => ingestion.getSchedules())
        .thenAnswer((_) async => const Ok([_agmarknet]));
    when(() => ingestion.getFilterOptions('s1'))
        .thenAnswer((_) async => Ok(_options));
    when(
      () => markets.importFeedMarkets(
        sourceId: any(named: 'sourceId'),
        state: any(named: 'state'),
        markets: any(named: 'markets'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        ImportMarketsResult(
          created: 1,
          skipped: [
            SkippedMarket(
              market: 'Anand',
              reason: FeedMarketSkipReason.alreadyInCatalog,
            ),
          ],
        ),
      ),
    );
  });

  test('the API answer is read, unknown reasons as the generic one', () {
    final result = AdminMarketsRepositoryImpl.parse({
      'created': 2,
      'skipped': [
        {'market': 'Anand', 'reason': 'AlreadyInCatalog'},
        {'market': 'Bhuj', 'reason': 'SomethingNew'},
      ],
    });

    expect(result.created, 2);
    expect(result.skipped.first.reason, FeedMarketSkipReason.alreadyInCatalog);
    expect(result.skipped.last.reason, FeedMarketSkipReason.nameInvalid);
  });

  group('AdminMarketsCubit', () {
    late AdminMarketsCubit cubit;

    setUp(() => cubit = AdminMarketsCubit(ingestion, markets));
    tearDown(() => cubit.close());

    test('loads the Agmarknet feed list', () async {
      await cubit.load();

      expect(cubit.state.setup.data?.sourceId, 's1');
      expect(cubit.state.setup.data?.options, _options);
    });

    test('is a failure when there is no Agmarknet source', () async {
      when(() => ingestion.getSchedules())
          .thenAnswer((_) async => const Ok([]));

      await cubit.load();

      expect(cubit.state.setup.status, LoadStatus.failure);
      verifyNever(() => ingestion.getFilterOptions(any()));
    });

    test('passes on a failure to load the sources', () async {
      when(() => ingestion.getSchedules())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.setup.failure, isA<NetworkFailure>());
    });

    test('an import keeps its result until the next one', () async {
      await cubit.load();

      await cubit.importMarkets('Gujarat', ['Rajkot', 'Anand']);

      verify(
        () => markets.importFeedMarkets(
          sourceId: 's1',
          state: 'Gujarat',
          markets: ['Rajkot', 'Anand'],
        ),
      ).called(1);
      expect(cubit.state.result?.created, 1);
      expect(cubit.state.importing, isFalse);
    });

    test('a refused import is kept to be shown once', () async {
      await cubit.load();
      when(
        () => markets.importFeedMarkets(
          sourceId: any(named: 'sourceId'),
          state: any(named: 'state'),
          markets: any(named: 'markets'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Add the state first.')),
      );

      await cubit.importMarkets('Gujarat', ['Rajkot']);

      expect(cubit.state.result, isNull);
      expect(cubit.state.importFailure, isA<ServerFailure>());
      cubit.failureShown();
      expect(cubit.state.importFailure, isNull);
    });

    test('nothing is sent for an empty choice or before loading', () async {
      await cubit.importMarkets('Gujarat', ['Rajkot']); // not loaded yet
      await cubit.load();
      await cubit.importMarkets('Gujarat', []);

      verifyNever(
        () => markets.importFeedMarkets(
          sourceId: any(named: 'sourceId'),
          state: any(named: 'state'),
          markets: any(named: 'markets'),
        ),
      );
    });
  });

  group('AdminMarketsPage', () {
    Future<AdminMarketsCubit> pump(WidgetTester tester) async {
      final cubit = AdminMarketsCubit(ingestion, markets);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminMarketsPage()),
      );
      return cubit;
    }

    testWidgets('before any full pull it says so and offers the pulls', (
      tester,
    ) async {
      when(() => ingestion.getFilterOptions('s1'))
          .thenAnswer((_) async => const Ok(FilterOptions()));
      await pump(tester);

      expect(find.textContaining('have not been recorded yet'), findsOneWidget);
      expect(find.text('Open data pulls'), findsOneWidget);
      expect(find.text('State'), findsNothing);
    });

    testWidgets('pick a state, select all its markets and add them', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Choose markets'), findsOneWidget);
      // Nothing to add until markets are chosen.
      expect(tester.widget<MbButton>(find.byType(MbButton)).onPressed, isNull);

      await tester.tap(find.text('Choose a state'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose markets'));
      await tester.pumpAndSettle();
      // Only that state's markets are offered.
      expect(find.text('APMC Pune'), findsNothing);
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Add 2 markets'), findsOneWidget);
      await tester.tap(find.text('Add 2 markets'));
      await tester.pumpAndSettle();

      verify(
        () => markets.importFeedMarkets(
          sourceId: 's1',
          state: 'Gujarat',
          markets: ['Rajkot', 'Anand'],
        ),
      ).called(1);
      expect(find.text('Added 1 market'), findsOneWidget);
      expect(find.text('Not added'), findsOneWidget);
      expect(find.text('Already in the catalog'), findsOneWidget);
      // The list is clear for the next import.
      expect(find.text('Choose markets'), findsOneWidget);
    });

    testWidgets('a refusal from the API is shown as its own message', (
      tester,
    ) async {
      when(
        () => markets.importFeedMarkets(
          sourceId: any(named: 'sourceId'),
          state: any(named: 'state'),
          markets: any(named: 'markets'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Add the state first.')),
      );
      await pump(tester);

      await tester.tap(find.text('Choose a state'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose markets'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 2 markets'));
      await tester.pumpAndSettle();

      expect(find.text('Add the state first.'), findsOneWidget);
    });

    testWidgets('a failed load shows an error with retry', (tester) async {
      when(() => ingestion.getSchedules())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
