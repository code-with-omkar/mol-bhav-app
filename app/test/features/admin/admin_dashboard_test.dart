import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_dashboard_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_dashboard.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/presentation/admin_dashboard_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_dashboard_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminDashboardRepository {}

const _json = <String, dynamic>{
  'users': {
    'total': 1240,
    'newLast7Days': 31,
    'activeLast7Days': 410,
    'suspended': 2,
    'pro': 90,
    'free': 1150,
  },
  'ads': {
    'impressionsToday': 500,
    'clicksToday': 20,
    'impressions7Days': 3000,
    'clicks7Days': 90,
    'clickRate7DaysPercent': 3.0,
    'activeCampaigns': 2,
    'rewardedViews7Days': 14,
  },
  'feeds': {
    'isDelayed': true,
    'lastSuccessAtUtc': '2026-10-16T14:20:25.0722450+00:00',
    'lastAttemptStatus': 'Failed',
    'lastAttemptAtUtc': '2026-10-17T00:30:00+00:00',
  },
  'support': {'openTickets': 5},
  'generatedAtUtc': '2026-10-17T06:30:00+00:00',
};

final _dashboard = AdminDashboardRepositoryImpl.parseDashboard(_json);

void main() {
  group('parseDashboard', () {
    test('reads every section', () {
      expect(_dashboard.users.total, 1240);
      expect(_dashboard.users.pro, 90);
      expect(_dashboard.ads.clicksToday, 20);
      expect(_dashboard.ads.clickRate7DaysPercent, 3.0);
      expect(_dashboard.feeds.isDelayed, isTrue);
      expect(_dashboard.feeds.lastAttemptStatus, IngestionJobStatus.failed);
      expect(_dashboard.openTickets, 5);
    });

    test('a feed that never ran has no last attempt', () {
      final j = {
        ..._json,
        'feeds': {'isDelayed': false},
      };

      final feeds = AdminDashboardRepositoryImpl.parseDashboard(j).feeds;

      expect(feeds.lastSuccessAt, isNull);
      expect(feeds.lastAttemptStatus, isNull);
    });
  });

  group('AdminDashboardCubit', () {
    late _MockRepository repository;
    late AdminDashboardCubit cubit;

    setUp(() {
      repository = _MockRepository();
      cubit = AdminDashboardCubit(repository);
    });

    tearDown(() => cubit.close());

    test('loads the dashboard', () async {
      when(() => repository.getOverview())
          .thenAnswer((_) async => Ok(_dashboard));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.data, _dashboard);
    });

    test('a failed refresh keeps the figures already shown', () async {
      when(() => repository.getOverview())
          .thenAnswer((_) async => Ok(_dashboard));
      await cubit.load();

      when(() => repository.getOverview())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.data, _dashboard);
    });

    test('a first load that fails has no data', () async {
      when(() => repository.getOverview())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.data, isNull);
    });
  });

  group('AdminDashboardPage', () {
    late _MockRepository repository;

    setUp(() => repository = _MockRepository());

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminDashboardCubit>.value(
          value: cubit,
          child: const AdminDashboardPage(),
        ),
      );
    }

    testWidgets('shows users, ads, price data and support figures', (
      tester,
    ) async {
      when(() => repository.getOverview())
          .thenAnswer((_) async => Ok(_dashboard));
      await pump(tester);

      expect(find.text('Admin dashboard'), findsOneWidget);
      expect(find.text('1,240'), findsOneWidget); // total users
      expect(find.text('Clicks today'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('3.0%'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Open tickets'), 200);
      expect(find.text('Delayed'), findsOneWidget); // price data badge
      expect(find.text('Open tickets'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('a failed first load shows an error with retry', (
      tester,
    ) async {
      when(() => repository.getOverview())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
