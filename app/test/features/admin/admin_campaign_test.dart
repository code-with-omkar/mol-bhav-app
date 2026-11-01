import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/domain/admin_ads.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminAdsRepository {}

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

const _campaign = CampaignPerformance(
  id: 'c1',
  name: 'Tata Agri Monsoon Sale',
  advertiserName: 'Tata Agri Ltd',
  placement: 'HomeFeed',
  status: CampaignState.active,
  impressions: 1000,
  clicks: 40,
  clickRatePercent: 4,
);

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.getCampaignDaily(
        campaignId: any(named: 'campaignId'),
        days: any(named: 'days'),
      ),
    ).thenAnswer(
      (_) async => Ok([
        AdsDay(day: _daysAgo(1), impressions: 600, clicks: 20),
        AdsDay(day: _daysAgo(0), impressions: 400, clicks: 20),
      ]),
    );
  });

  group('AdsDay', () {
    test('click rate is clicks per hundred impressions, 0 when none shown', () {
      expect(
        AdsDay(day: _daysAgo(0), impressions: 400, clicks: 20).clickRatePercent,
        5,
      );
      expect(
        AdsDay(day: _daysAgo(0), impressions: 0, clicks: 0).clickRatePercent,
        0,
      );
    });
  });

  group('AdminCampaignCubit', () {
    late AdminCampaignCubit cubit;

    setUp(() => cubit = AdminCampaignCubit(repository));
    tearDown(() => cubit.close());

    test('fills days with no delivery with zeros, oldest first', () async {
      await cubit.load('c1');

      final rows = cubit.state.data.data!;
      expect(rows, hasLength(30));
      expect(rows.last.clicks, 20);
      expect(rows[rows.length - 2].impressions, 600);
      expect(rows.first.impressions, 0);
      expect(rows.first.day.isBefore(rows.last.day), isTrue);
    });

    test('picking another range reloads the same campaign', () async {
      await cubit.load('c1');

      await cubit.setDays(7);

      expect(cubit.state.days, 7);
      expect(cubit.state.data.data, hasLength(7));
      verify(() => repository.getCampaignDaily(campaignId: 'c1', days: 7))
          .called(1);
    });

    test('a failed reload keeps the figures already shown', () async {
      await cubit.load('c1');
      when(
        () => repository.getCampaignDaily(
          campaignId: any(named: 'campaignId'),
          days: any(named: 'days'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.reload();

      expect(cubit.state.data.status, LoadStatus.failure);
      expect(cubit.state.data.data, hasLength(30));
    });
  });

  group('AdminCampaignPage', () {
    Future<void> pump(WidgetTester tester, {CampaignPerformance? c}) async {
      final cubit = AdminCampaignCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('c1');
      await tester.pumpApp(
        BlocProvider<AdminCampaignCubit>.value(
          value: cubit,
          child: AdminCampaignPage(campaignId: 'c1', campaign: c),
        ),
      );
    }

    testWidgets('shows the campaign, its totals and the charts', (
      tester,
    ) async {
      await pump(tester, c: _campaign);

      expect(find.text('Tata Agri Monsoon Sale'), findsOneWidget);
      expect(find.text('Tata Agri Ltd · Home Feed'), findsOneWidget);
      expect(find.text('40'), findsOneWidget); // clicks
      expect(find.text('4.0%'), findsOneWidget); // 40 of 1,000
      expect(find.text('Impressions per day'), findsOneWidget);
      expect(find.text('Clicks per day'), findsOneWidget);
    });

    testWidgets('without the campaign row it still shows the figures', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Campaign'), findsOneWidget);
      expect(find.text('Clicks per day'), findsOneWidget);
    });

    testWidgets('says so when nothing was shown', (tester) async {
      when(
        () => repository.getCampaignDaily(
          campaignId: any(named: 'campaignId'),
          days: any(named: 'days'),
        ),
      ).thenAnswer((_) async => const Ok(<AdsDay>[]));
      await pump(tester, c: _campaign);

      expect(
        find.text('No ads were shown for this campaign in this range.'),
        findsOneWidget,
      );
    });
  });
}
