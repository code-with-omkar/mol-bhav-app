import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_commodities_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_commodities.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/presentation/admin_commodities_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_commodities_page.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockIngestion extends Mock implements AdminIngestionRepository {}

class _MockCommodities extends Mock implements AdminCommoditiesRepository {}

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
  states: const ['Gujarat'],
  commodities: const ['Onion', 'Tomato', 'Potato'],
  markets: const [FilterMarket(name: 'Rajkot', state: 'Gujarat')],
  refreshedAt: DateTime(2026, 11, 1),
);

const _targets = CommodityTargets(
  subCategories: [CatalogChoice(id: 'sc1', label: 'Vegetables › Roots')],
  units: [CatalogChoice(id: 'u1', label: 'Quintal (qtl)')],
);

void main() {
  late _MockIngestion ingestion;
  late _MockCommodities commodities;

  setUp(() {
    ingestion = _MockIngestion();
    commodities = _MockCommodities();
    when(() => ingestion.getSchedules())
        .thenAnswer((_) async => const Ok([_agmarknet]));
    when(() => ingestion.getFilterOptions('s1'))
        .thenAnswer((_) async => Ok(_options));
    when(() => commodities.getTargets())
        .thenAnswer((_) async => const Ok(_targets));
    when(
      () => commodities.importFeedProducts(
        sourceId: any(named: 'sourceId'),
        subCategoryId: any(named: 'subCategoryId'),
        unitId: any(named: 'unitId'),
        commodities: any(named: 'commodities'),
      ),
    ).thenAnswer(
      (_) async => const Ok(
        ImportCommoditiesResult(
          created: 2,
          skipped: [
            SkippedCommodity(
              commodity: 'Potato',
              reason: FeedCommoditySkipReason.alreadyInCatalog,
            ),
          ],
        ),
      ),
    );
  });

  test('the API answer is read, unknown reasons as the generic one', () {
    final result = AdminCommoditiesRepositoryImpl.parse({
      'created': 1,
      'skipped': [
        {'commodity': 'Potato', 'reason': 'AlreadyInCatalog'},
        {'commodity': 'Ginger', 'reason': 'SomethingNew'},
      ],
    });

    expect(result.created, 1);
    expect(
      result.skipped.first.reason,
      FeedCommoditySkipReason.alreadyInCatalog,
    );
    expect(result.skipped.last.reason, FeedCommoditySkipReason.nameInvalid);
  });

  test(
    'targets list active sub-categories and units by their English name',
    () {
      Map<String, dynamic> tr(String lang, String name) => {
        'languageCode': lang,
        'name': name,
      };
      final targets = AdminCommoditiesRepositoryImpl.parseTargets(
        [
          {
            'code': 'veg',
            'isActive': true,
            'translations': [tr('hi', 'सब्ज़ी'), tr('en', 'Vegetables')],
            'subCategories': [
              {
                'id': 'sc1',
                'code': 'roots',
                'isActive': true,
                'translations': [tr('en', 'Roots')],
              },
              {
                'id': 'sc2',
                'code': 'old',
                'isActive': false,
                'translations': [tr('en', 'Old')],
              },
            ],
          },
          {
            'code': 'gone',
            'isActive': false,
            'translations': [tr('en', 'Gone')],
            'subCategories': [
              {'id': 'sc3', 'code': 'x', 'isActive': true, 'translations': []},
            ],
          },
        ],
        [
          {
            'id': 'u1',
            'code': 'qtl',
            'symbol': 'qtl',
            'isActive': true,
            'translations': [tr('en', 'Quintal')],
          },
          {
            'id': 'u2',
            'code': 'kg',
            'symbol': 'kg',
            'isActive': false,
            'translations': [tr('en', 'Kilogram')],
          },
        ],
      );

      expect(targets.subCategories, const [
        CatalogChoice(id: 'sc1', label: 'Vegetables › Roots'),
      ]);
      expect(targets.units, const [
        CatalogChoice(id: 'u1', label: 'Quintal (qtl)'),
      ]);
    },
  );

  test('a name falls back to the code when there are no translations', () {
    final targets = AdminCommoditiesRepositoryImpl.parseTargets([
      {
        'code': 'veg',
        'isActive': true,
        'translations': [],
        'subCategories': [
          {'id': 'sc1', 'code': 'roots', 'isActive': true},
        ],
      },
    ], const []);

    expect(targets.subCategories.single.label, 'veg › roots');
  });

  group('AdminCommoditiesCubit', () {
    late AdminCommoditiesCubit cubit;

    setUp(() => cubit = AdminCommoditiesCubit(ingestion, commodities));
    tearDown(() => cubit.close());

    test('loads the feed list and where products can go', () async {
      await cubit.load();

      expect(cubit.state.setup.data?.sourceId, 's1');
      expect(cubit.state.setup.data?.options, _options);
      expect(cubit.state.setup.data?.targets, _targets);
    });

    test('is a failure when there is no Agmarknet source', () async {
      when(() => ingestion.getSchedules())
          .thenAnswer((_) async => const Ok([]));

      await cubit.load();

      expect(cubit.state.setup.status, LoadStatus.failure);
      verifyNever(() => ingestion.getFilterOptions(any()));
    });

    test('is a failure when the catalog lists cannot be loaded', () async {
      when(() => commodities.getTargets())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.setup.failure, isA<NetworkFailure>());
    });

    test('an import keeps its result until the next one', () async {
      await cubit.load();

      await cubit.importCommodities(
        subCategoryId: 'sc1',
        unitId: 'u1',
        commodities: ['Onion', 'Tomato'],
      );

      verify(
        () => commodities.importFeedProducts(
          sourceId: 's1',
          subCategoryId: 'sc1',
          unitId: 'u1',
          commodities: ['Onion', 'Tomato'],
        ),
      ).called(1);
      expect(cubit.state.result?.created, 2);
      expect(cubit.state.importing, isFalse);
    });

    test('a refused import is kept to be shown once', () async {
      await cubit.load();
      when(
        () => commodities.importFeedProducts(
          sourceId: any(named: 'sourceId'),
          subCategoryId: any(named: 'subCategoryId'),
          unitId: any(named: 'unitId'),
          commodities: any(named: 'commodities'),
        ),
      ).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Sub-category not found.')),
      );

      await cubit.importCommodities(
        subCategoryId: 'sc1',
        unitId: 'u1',
        commodities: ['Onion'],
      );

      expect(cubit.state.result, isNull);
      expect(cubit.state.importFailure, isA<ServerFailure>());
      cubit.failureShown();
      expect(cubit.state.importFailure, isNull);
    });

    test('nothing is sent for an empty choice or before loading', () async {
      await cubit.importCommodities(
        subCategoryId: 'sc1',
        unitId: 'u1',
        commodities: ['Onion'],
      ); // not loaded yet
      await cubit.load();
      await cubit.importCommodities(
        subCategoryId: 'sc1',
        unitId: 'u1',
        commodities: [],
      );

      verifyNever(
        () => commodities.importFeedProducts(
          sourceId: any(named: 'sourceId'),
          subCategoryId: any(named: 'subCategoryId'),
          unitId: any(named: 'unitId'),
          commodities: any(named: 'commodities'),
        ),
      );
    });
  });

  group('AdminCommoditiesPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminCommoditiesCubit(ingestion, commodities);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminCommoditiesPage()),
      );
    }

    Future<void> chooseTargets(WidgetTester tester) async {
      await tester.tap(find.text('Choose a sub-category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vegetables › Roots'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a unit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quintal (qtl)'));
      await tester.pumpAndSettle();
    }

    testWidgets('before any full pull it says so and offers the pulls', (
      tester,
    ) async {
      when(() => ingestion.getFilterOptions('s1'))
          .thenAnswer((_) async => const Ok(FilterOptions()));
      await pump(tester);

      expect(find.textContaining('have not been recorded yet'), findsOneWidget);
      expect(find.text('Open data pulls'), findsOneWidget);
      expect(find.text('Unit'), findsNothing);
    });

    testWidgets('sub-category, unit and commodities are all needed to add', (
      tester,
    ) async {
      await pump(tester);
      expect(tester.widget<MbButton>(find.byType(MbButton)).onPressed, isNull);

      await chooseTargets(tester);
      // Targets alone are not enough.
      expect(tester.widget<MbButton>(find.byType(MbButton)).onPressed, isNull);

      await tester.tap(find.text('Choose commodities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MbButton>(find.byType(MbButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('pick targets, select all commodities and add them', (
      tester,
    ) async {
      await pump(tester);
      await chooseTargets(tester);

      await tester.tap(find.text('Choose commodities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Add 3 commodities'), findsOneWidget);
      await tester.tap(find.text('Add 3 commodities'));
      await tester.pumpAndSettle();

      verify(
        () => commodities.importFeedProducts(
          sourceId: 's1',
          subCategoryId: 'sc1',
          unitId: 'u1',
          commodities: ['Onion', 'Tomato', 'Potato'],
        ),
      ).called(1);
      expect(find.text('Added 2 commodities'), findsOneWidget);
      expect(find.text('Not added'), findsOneWidget);
      expect(find.text('Already in the catalog'), findsOneWidget);
      // The list is clear for the next import.
      expect(find.text('Choose commodities'), findsOneWidget);
    });

    testWidgets('a refusal from the API is shown as its own message', (
      tester,
    ) async {
      when(
        () => commodities.importFeedProducts(
          sourceId: any(named: 'sourceId'),
          subCategoryId: any(named: 'subCategoryId'),
          unitId: any(named: 'unitId'),
          commodities: any(named: 'commodities'),
        ),
      ).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Run a full pull first.')),
      );
      await pump(tester);
      await chooseTargets(tester);
      await tester.tap(find.text('Choose commodities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add 3 commodities'));
      await tester.pumpAndSettle();

      expect(find.text('Run a full pull first.'), findsOneWidget);
      expect(find.text('Added 2 commodities'), findsNothing);
    });
  });
}
