import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_ads_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_ads.dart';
import 'package:mol_bhav/features/admin/presentation/admin_ads_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_ads_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminAdsRepository {}

const _json = <String, dynamic>{
  'from': '2026-09-18',
  'to': '2026-10-17',
  'impressions': 1500,
  'clicks': 45,
  'clickRatePercent': 3.0,
  'campaigns': [
    {
      'id': 'c1',
      'name': 'Tata Agri Monsoon Sale',
      'advertiserName': 'Tata Agri Ltd',
      'placement': 'HomeFeed',
      'status': 'Active',
      'impressions': 1000,
      'clicks': 40,
      'clickRatePercent': 4.0,
    },
    {
      'id': 'c2',
      'name': 'Old Smoke Test',
      'advertiserName': 'Smoke Test Seeds',
      'placement': 'MarketComparison',
      'status': 'Ended',
      'impressions': 500,
      'clicks': 5,
      'clickRatePercent': 1.0,
    },
  ],
  'daily': [
    {'day': '2026-10-15', 'impressions': 700, 'clicks': 20},
    {'day': '2026-10-16', 'impressions': 800, 'clicks': 25},
  ],
};

final _overview = AdminAdsRepositoryImpl.parseOverview(_json);

void main() {
  group('parseOverview', () {
    test('reads totals, campaigns and daily points', () {
      expect(_overview.clicks, 45);
      expect(_overview.clickRatePercent, 3.0);
      expect(_overview.campaigns, hasLength(2));
      expect(_overview.campaigns.first.name, 'Tata Agri Monsoon Sale');
      expect(_overview.campaigns.first.status, CampaignState.active);
      expect(_overview.daily.last.clicks, 25);
      expect(_overview.from, DateTime(2026, 9, 18));
    });

    test('placements read as words, unknown statuses as draft', () {
      expect(_overview.campaigns.last.placementLabel, 'Market Comparison');
      expect(CampaignState.fromWire('Paused'), CampaignState.paused);
      expect(CampaignState.fromWire('SomethingNew'), CampaignState.draft);
    });
  });

  group('placements', () {
    test('campaigns are added up per placement, most clicks first', () {
      final placements = AdsOverview(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 30),
        impressions: 0,
        clicks: 0,
        clickRatePercent: 0,
        daily: const [],
        campaigns: [
          for (final (id, placement, imp, clk) in [
            ('a', 'MandiPrices', 100, 2),
            ('b', 'HomeFeed', 300, 9),
            ('c', 'HomeFeed', 100, 1),
          ])
            CampaignPerformance(
              id: id,
              name: id,
              advertiserName: 'x',
              placement: placement,
              status: CampaignState.active,
              impressions: imp,
              clicks: clk,
              clickRatePercent: 0,
            ),
        ],
      ).byPlacement;

      expect(placements.map((p) => p.placement), ['HomeFeed', 'MandiPrices']);
      expect(placements.first.campaigns, 2);
      expect(placements.first.impressions, 400);
      expect(placements.first.clicks, 10);
      expect(placements.first.clickRatePercent, 2.5);
      expect(placements.first.label, 'Home Feed');
    });

    test('no delivery is a 0% click rate, not a division by zero', () {
      const empty = PlacementPerformance(
        placement: 'HomeFeed',
        campaigns: 1,
        impressions: 0,
        clicks: 0,
      );
      expect(empty.clickRatePercent, 0);
    });

    testWidgets('the page lists each placement with its campaigns', (
      tester,
    ) async {
      final repository = _MockRepository();
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => Ok(_overview));
      final cubit = AdminAdsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminAdsCubit>.value(
          value: cubit,
          child: const AdminAdsPage(),
        ),
      );

      await tester.scrollUntilVisible(find.text('Market Comparison'), 200);
      expect(find.text('Placements'), findsOneWidget);
      expect(find.text('Home Feed'), findsWidgets);
      expect(find.text('1 campaign'), findsWidgets);
    });
  });

  group('comparison with the previous range', () {
    const previousJson = <String, dynamic>{
      'from': '2026-08-19',
      'to': '2026-09-17',
      'impressions': 1000,
      'clicks': 30,
      'clickRatePercent': 3.0,
      'campaigns': [
        {
          'id': 'c1',
          'name': 'Tata Agri Monsoon Sale',
          'advertiserName': 'Tata Agri Ltd',
          'placement': 'HomeFeed',
          'status': 'Active',
          'impressions': 800,
          'clicks': 20,
          'clickRatePercent': 2.5,
        },
      ],
      'daily': <Map<String, dynamic>>[],
    };
    final withPrevious = _overview.withPrevious(
      AdminAdsRepositoryImpl.parseOverview(previousJson),
    );

    test('percent change, and none when there is no base', () {
      expect(percentChange(45, 30), 50);
      expect(percentChange(15, 30), -50);
      expect(percentChange(5, 0), isNull);
    });

    test('a campaign is found in the previous range by id', () {
      expect(withPrevious.previousCampaign('c1')?.clicks, 20);
      expect(withPrevious.previousCampaign('c2'), isNull);
      expect(_overview.previousCampaign('c1'), isNull);
    });

    testWidgets('the totals and campaigns show how they moved', (tester) async {
      final repository = _MockRepository();
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => Ok(withPrevious));
      final cubit = AdminAdsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminAdsCubit>.value(
          value: cubit,
          child: const AdminAdsPage(),
        ),
      );

      // Clicks 45 vs 30 and impressions 1,500 vs 1,000: both +50%.
      expect(find.text('▲ +50.0%'), findsNWidgets(2));
      expect(find.text('0.0 pts'), findsOneWidget); // 3.0% vs 3.0%
      expect(
        find.textContaining('Change compared with the previous 30 days'),
        findsOneWidget,
      );

      // c1 doubled its clicks (40 vs 20); c2 was not delivering before.
      await tester.scrollUntilVisible(find.text('Old Smoke Test'), 200);
      // (the Home Feed placement holds only c1, so it doubled as well)
      expect(find.text('▲ +100.0%'), findsNWidgets(2));
      expect(find.text('▲ New'), findsWidgets);
    });

    testWidgets('without a previous range nothing is compared', (tester) async {
      final repository = _MockRepository();
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => Ok(_overview));
      final cubit = AdminAdsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminAdsCubit>.value(
          value: cubit,
          child: const AdminAdsPage(),
        ),
      );

      expect(find.textContaining('▲'), findsNothing);
      expect(find.textContaining('Change compared'), findsNothing);
    });
  });

  group('AdminAdsCubit', () {
    late _MockRepository repository;
    late AdminAdsCubit cubit;

    setUp(() {
      repository = _MockRepository();
      cubit = AdminAdsCubit(repository);
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => Ok(_overview));
    });

    tearDown(() => cubit.close());

    test('loads the last 30 days first', () async {
      await cubit.load();

      expect(cubit.state.days, 30);
      expect(cubit.state.data.data, _overview);
      verify(() => repository.getOverview(days: 30)).called(1);
    });

    test('picking another range reloads for it', () async {
      await cubit.load();

      await cubit.setDays(7);

      expect(cubit.state.days, 7);
      verify(() => repository.getOverview(days: 7)).called(1);
    });

    test('picking the range already shown does nothing', () async {
      await cubit.load();

      await cubit.setDays(30);

      verify(() => repository.getOverview(days: 30)).called(1);
    });

    test('an answer for a range no longer selected is ignored', () async {
      // The 30-day answer arrives only after the admin has picked 7 days.
      var release = Future<void>.value();
      Future<Result<AdsOverview>> slow() async {
        await release;
        return Ok(_overview);
      }

      release = Future<void>.delayed(const Duration(milliseconds: 20));
      when(() => repository.getOverview(days: 30)).thenAnswer((_) => slow());
      final first = cubit.load();
      await cubit.setDays(7);
      await first;

      expect(cubit.state.days, 7);
      expect(cubit.state.data.status, LoadStatus.ready);
    });

    test('a failed reload keeps the figures already shown', () async {
      await cubit.load();
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.data.status, LoadStatus.failure);
      expect(cubit.state.data.data, _overview);
    });
  });

  group('AdminAdsPage', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => Ok(_overview));
    });

    Future<AdminAdsCubit> pump(WidgetTester tester) async {
      final cubit = AdminAdsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminAdsCubit>.value(
          value: cubit,
          child: const AdminAdsPage(),
        ),
      );
      return cubit;
    }

    testWidgets('shows totals, the range chips and each campaign', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
      expect(find.text('45'), findsOneWidget); // total clicks
      expect(find.text('3.0%'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Old Smoke Test'), 200);
      expect(find.text('Tata Agri Monsoon Sale'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('tapping a range loads it', (tester) async {
      await pump(tester);

      await tester.tap(find.text('7 days'));
      await tester.pump();

      verify(() => repository.getOverview(days: 7)).called(1);
    });

    testWidgets('a failed first load shows an error', (tester) async {
      when(() => repository.getOverview(days: any(named: 'days')))
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
