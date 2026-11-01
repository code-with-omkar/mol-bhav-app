import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_dashboard_data.dart';
import 'package:mol_bhav/features/admin/data/admin_jobs_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_dashboard.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/domain/admin_jobs.dart';
import 'package:mol_bhav/features/admin/presentation/admin_app_page.dart';
import 'package:mol_bhav/features/admin/presentation/admin_dashboard_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/pull_history_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/pull_history_page.dart';
import 'package:mol_bhav/features/admin/presentation/pull_job_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/pull_job_page.dart';

import '../../helpers/pump_app.dart';

class _MockJobs extends Mock implements AdminJobsRepository {}

class _MockDashboard extends Mock implements AdminDashboardRepository {}

Map<String, dynamic> _jobJson({
  String id = 'j1',
  String status = 'PartiallySucceeded',
  String trigger = 'Scheduled',
  int failed = 2,
  String? reason,
}) => {
  'id': id,
  'priceSourceId': 's1',
  'priceSourceCode': 'agmarknet',
  'triggerType': trigger,
  'status': status,
  'asOfDate': '2026-10-14',
  'recordsFetched': 35,
  'recordsPersisted': 9,
  'recordsUnchanged': 25,
  'recordsFailed': failed,
  'failureReason': reason,
  'startedAtUtc': '2026-10-16T01:00:00+00:00',
  'completedAtUtc': '2026-10-16T01:05:00+00:00',
};

AdminJob _job({
  String id = 'j1',
  String status = 'PartiallySucceeded',
  String trigger = 'Scheduled',
  int failed = 2,
  String? reason,
}) => AdminJobsRepositoryImpl.parseJob(
  _jobJson(
    id: id,
    status: status,
    trigger: trigger,
    failed: failed,
    reason: reason,
  ),
);

AdminJobError _error(String id, String message) =>
    AdminJobsRepositoryImpl.parseError({
      'id': id,
      'jobId': 'j1',
      'rawPayload': '{"commodity":"Dragon Fruit"}',
      'errorMessage': message,
      'occurredAtUtc': '2026-10-16T01:02:00+00:00',
    });

void main() {
  setUpAll(() => registerFallbackValue(JobListFilter.all));

  group('parsing', () {
    test('a run', () {
      final j = _job(
        trigger: 'Upload',
        status: 'Failed',
        reason: 'Source down',
      );

      expect(j.sourceCode, 'agmarknet');
      expect(j.trigger, JobTrigger.upload);
      expect(j.status, IngestionJobStatus.failed);
      expect(j.asOfDate, DateTime(2026, 10, 14));
      expect(j.persisted, 9);
      expect(j.unchanged, 25);
      expect(j.failureReason, 'Source down');
    });

    test('an unknown trigger reads as manual', () {
      expect(JobTrigger.fromWire('Something'), JobTrigger.manual);
      expect(JobTrigger.fromWire('SCHEDULED'), JobTrigger.scheduled);
    });

    test('a failed row keeps the source data verbatim', () {
      final e = _error('e1', 'No active product');

      expect(e.message, 'No active product');
      expect(e.rawPayload, '{"commodity":"Dragon Fruit"}');
    });

    test('the filter maps to the API status', () {
      expect(JobListFilter.all.wire, isNull);
      expect(JobListFilter.failed.wire, 'Failed');
      expect(JobListFilter.partial.wire, 'PartiallySucceeded');
      expect(JobListFilter.succeeded.wire, 'Succeeded');
    });
  });

  group('PullHistoryCubit', () {
    late _MockJobs repository;
    late PullHistoryCubit cubit;

    List<AdminJob> page(int n, {int from = 0}) => [
      for (var i = 0; i < n; i++) _job(id: 'j${from + i}'),
    ];

    void serve(List<AdminJob> jobs, {int? pageNo}) => when(
      () => repository.getJobs(
        filter: any(named: 'filter'),
        page: pageNo ?? any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok(jobs));

    setUp(() {
      repository = _MockJobs();
      cubit = PullHistoryCubit(repository);
    });

    tearDown(() => cubit.close());

    test('loads the newest runs; a short page ends the list', () async {
      serve(page(3));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.jobs, hasLength(3));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a full page allows loading more, which appends', () async {
      serve(page(PullHistoryCubit.pageSize), pageNo: 1);
      serve(page(4, from: 100), pageNo: 2);
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.jobs, hasLength(PullHistoryCubit.pageSize + 4));
      expect(cubit.state.hasMore, isFalse);
    });

    test(
      'changing the filter reloads from page 1; the same filter does not',
      () async {
        serve(page(2));
        await cubit.load();

        await cubit.setFilter(JobListFilter.failed);
        await cubit.setFilter(JobListFilter.failed);

        verify(
          () => repository.getJobs(
            filter: JobListFilter.failed,
            page: 1,
            pageSize: PullHistoryCubit.pageSize,
          ),
        ).called(1);
      },
    );

    test('a failed first load reports the failure', () async {
      when(
        () => repository.getJobs(
          filter: any(named: 'filter'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });
  });

  group('PullJobCubit', () {
    late _MockJobs repository;
    late PullJobCubit cubit;

    setUp(() {
      repository = _MockJobs();
      cubit = PullJobCubit(repository);
    });

    tearDown(() => cubit.close());

    test('loads the run and the rows that failed', () async {
      when(() => repository.getJob('j1')).thenAnswer((_) async => Ok(_job()));
      when(
        () => repository.getErrors(
          'j1',
          page: 1,
          pageSize: PullJobCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok([_error('e1', 'No active product')]));

      await cubit.load('j1');

      expect(cubit.state.job.data?.sourceCode, 'agmarknet');
      expect(cubit.state.errors, hasLength(1));
      expect(cubit.state.hasMoreErrors, isFalse);
    });

    test('a run with no failed rows asks for no errors', () async {
      when(() => repository.getJob('j1'))
          .thenAnswer((_) async => Ok(_job(failed: 0, status: 'Succeeded')));

      await cubit.load('j1');

      expect(cubit.state.errors, isEmpty);
      verifyNever(
        () => repository.getErrors(
          any(),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('more failed rows append page by page', () async {
      when(() => repository.getJob('j1'))
          .thenAnswer((_) async => Ok(_job(failed: 25)));
      when(
        () => repository.getErrors(
          'j1',
          page: 1,
          pageSize: PullJobCubit.pageSize,
        ),
      ).thenAnswer(
        (_) async => Ok([
          for (var i = 0; i < PullJobCubit.pageSize; i++) _error('a$i', 'x'),
        ]),
      );
      when(
        () => repository.getErrors(
          'j1',
          page: 2,
          pageSize: PullJobCubit.pageSize,
        ),
      ).thenAnswer(
        (_) async => Ok([for (var i = 0; i < 5; i++) _error('b$i', 'y')]),
      );
      await cubit.load('j1');
      expect(cubit.state.hasMoreErrors, isTrue);

      await cubit.loadMoreErrors('j1');

      expect(cubit.state.errors, hasLength(PullJobCubit.pageSize + 5));
      expect(cubit.state.hasMoreErrors, isFalse);
    });

    test('the run still shows when its failed rows cannot be loaded', () async {
      when(() => repository.getJob('j1')).thenAnswer((_) async => Ok(_job()));
      when(
        () => repository.getErrors(
          any(),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load('j1');

      expect(cubit.state.job.data, isNotNull);
      expect(cubit.state.errorsFailure, isNotNull);
    });
  });

  group('pages', () {
    late _MockJobs repository;

    setUp(() => repository = _MockJobs());

    testWidgets(
      'the history lists runs with outcome, counts and failure reason',
      (tester) async {
        when(
          () => repository.getJobs(
            filter: any(named: 'filter'),
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => Ok([
            _job(id: 'j1'),
            _job(
              id: 'j2',
              status: 'Failed',
              failed: 0,
              reason: 'The connection failed on 5 attempts',
            ),
          ]),
        );
        final cubit = PullHistoryCubit(repository);
        addTearDown(cubit.close);
        await cubit.load();

        await tester.pumpApp(
          BlocProvider<PullHistoryCubit>.value(
            value: cubit,
            child: const PullHistoryPage(),
          ),
        );

        expect(find.text('agmarknet'), findsNWidgets(2));
        expect(
          find.textContaining('9 saved, 2 failed, 25 unchanged'),
          findsOneWidget,
        );
        expect(
          find.textContaining('The connection failed on 5 attempts'),
          findsOneWidget,
        );
        expect(find.widgetWithText(ChoiceChip, 'Failed'), findsOneWidget);
      },
    );

    testWidgets('picking a filter chip reloads the history', (tester) async {
      when(
        () => repository.getJobs(
          filter: any(named: 'filter'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Ok([_job()]));
      final cubit = PullHistoryCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<PullHistoryCubit>.value(
          value: cubit,
          child: const PullHistoryPage(),
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Failed'));
      await tester.pump();

      verify(
        () => repository.getJobs(
          filter: JobListFilter.failed,
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    testWidgets('the run page shows the failed rows with their source data', (
      tester,
    ) async {
      when(() => repository.getJob('j1')).thenAnswer((_) async => Ok(_job()));
      when(
        () => repository.getErrors(
          'j1',
          page: 1,
          pageSize: PullJobCubit.pageSize,
        ),
      ).thenAnswer(
        (_) async =>
            Ok([_error('e1', 'No active product with code dragon-fruit')]),
      );
      final cubit = PullJobCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('j1');

      await tester.pumpApp(
        BlocProvider<PullJobCubit>.value(
          value: cubit,
          child: const PullJobPage(jobId: 'j1'),
        ),
      );

      expect(find.text('Rows that failed'), findsOneWidget);
      expect(
        find.text('No active product with code dragon-fruit'),
        findsOneWidget,
      );
      expect(find.textContaining('Dragon Fruit'), findsOneWidget);
    });

    testWidgets('a run with no failed rows has no failed-rows section', (
      tester,
    ) async {
      when(() => repository.getJob('j1'))
          .thenAnswer((_) async => Ok(_job(failed: 0, status: 'Succeeded')));
      final cubit = PullJobCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('j1');

      await tester.pumpApp(
        BlocProvider<PullJobCubit>.value(
          value: cubit,
          child: const PullJobPage(jobId: 'j1'),
        ),
      );

      expect(find.text('Rows that failed'), findsNothing);
    });
  });

  group('App management hub', () {
    testWidgets('shows feed health and the entries', (tester) async {
      final dashboards = _MockDashboard();
      when(() => dashboards.getOverview()).thenAnswer(
        (_) async => Ok(
          AdminDashboardRepositoryImpl.parseDashboard({
            'users': {
              'total': 1,
              'newLast7Days': 0,
              'activeLast7Days': 0,
              'suspended': 0,
              'pro': 0,
              'free': 1,
            },
            'ads': {
              'impressionsToday': 0,
              'clicksToday': 0,
              'impressions7Days': 0,
              'clicks7Days': 0,
              'clickRate7DaysPercent': 0,
              'activeCampaigns': 0,
              'rewardedViews7Days': 0,
            },
            'feeds': {'isDelayed': true, 'lastAttemptStatus': 'Failed'},
            'support': {'openTickets': 0},
            'generatedAtUtc': '2026-10-17T06:30:00+00:00',
          }),
        ),
      );
      final cubit = AdminDashboardCubit(dashboards);
      addTearDown(cubit.close);
      await cubit.load();

      await tester.pumpApp(
        BlocProvider<AdminDashboardCubit>.value(
          value: cubit,
          child: const AdminAppPage(),
        ),
      );

      expect(find.text('Price data'), findsOneWidget);
      expect(find.text('Delayed'), findsOneWidget);
      expect(find.text('Data pull schedules'), findsOneWidget);
      expect(find.text('Pull history'), findsOneWidget);
    });

    testWidgets(
      'the entries are there even when the feed card could not load',
      (tester) async {
        final dashboards = _MockDashboard();
        when(() => dashboards.getOverview())
            .thenAnswer((_) async => const Err(NetworkFailure()));
        final cubit = AdminDashboardCubit(dashboards);
        addTearDown(cubit.close);
        await cubit.load();

        await tester.pumpApp(
          BlocProvider<AdminDashboardCubit>.value(
            value: cubit,
            child: const AdminAppPage(),
          ),
        );

        expect(find.text('Price data'), findsNothing);
        expect(find.text('Data pull schedules'), findsOneWidget);
        expect(find.text('Pull history'), findsOneWidget);
      },
    );
  });
}
