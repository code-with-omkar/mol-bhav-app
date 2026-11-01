import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_audit_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_audit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_audit_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_audit_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminAuditRepository {}

AuditEntry _entry(int n, {String? actor = 'Omkar'}) => AuditEntry(
  id: 'e$n',
  occurredAt: DateTime(2026, 11, 1, 10, n % 60),
  action: 'Feature.Set',
  summary: 'Turned Ads off #$n',
  target: 'Ads',
  actorName: actor,
);

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.getEntries(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok([_entry(1), _entry(2)]));
  });

  test('an API row is read, blank text as missing', () {
    final entry = AdminAuditRepositoryImpl.parse({
      'id': 'a1',
      'occurredAtUtc': '2026-11-01T04:30:00+00:00',
      'action': 'User.Suspend',
      'target': ' ',
      'summary': 'Suspended a user account',
      'actorUserId': 'u1',
      'actorName': null,
    });

    expect(entry.action, 'User.Suspend');
    expect(entry.area, 'User');
    expect(entry.target, isNull);
    expect(entry.actorName, isNull);
    expect(entry.occurredAt.toUtc(), DateTime.utc(2026, 11, 1, 4, 30));
  });

  group('AdminAuditCubit', () {
    late AdminAuditCubit cubit;

    setUp(() => cubit = AdminAuditCubit(repository));
    tearDown(() => cubit.close());

    test('loads the first page; a short page means there is no more', () async {
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.entries, hasLength(2));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a full page offers more, and more is added to the end', () async {
      final full = [
        for (var i = 0; i < AdminAuditCubit.pageSize; i++) _entry(i),
      ];
      when(
        () =>
            repository.getEntries(page: 1, pageSize: AdminAuditCubit.pageSize),
      ).thenAnswer((_) async => Ok(full));
      when(
        () =>
            repository.getEntries(page: 2, pageSize: AdminAuditCubit.pageSize),
      ).thenAnswer((_) async => Ok([_entry(99)]));

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.entries, hasLength(AdminAuditCubit.pageSize + 1));
      expect(cubit.state.entries.last.id, 'e99');
      expect(cubit.state.hasMore, isFalse);
    });

    test('a failed load-more keeps the entries shown', () async {
      final full = [
        for (var i = 0; i < AdminAuditCubit.pageSize; i++) _entry(i),
      ];
      when(
        () =>
            repository.getEntries(page: 1, pageSize: AdminAuditCubit.pageSize),
      ).thenAnswer((_) async => Ok(full));
      when(
        () =>
            repository.getEntries(page: 2, pageSize: AdminAuditCubit.pageSize),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      await cubit.load();

      await cubit.loadMore();

      expect(cubit.state.entries, hasLength(AdminAuditCubit.pageSize));
      expect(cubit.state.loadingMore, isFalse);
      expect(cubit.state.hasMore, isTrue);
    });

    test('a failed first load is a failure with no entries', () async {
      when(
        () => repository.getEntries(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.entries, isEmpty);
    });
  });

  group('AdminAuditPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminAuditCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminAuditPage()),
      );
    }

    testWidgets('lists what was done, by whom, with its area', (tester) async {
      await pump(tester);

      expect(find.text('Turned Ads off #1'), findsOneWidget);
      expect(find.textContaining('by Omkar'), findsNWidgets(2));
      expect(find.text('Feature'), findsNWidgets(2)); // the area badge
      expect(find.text('Ads'), findsNWidgets(2)); // the target
    });

    testWidgets('an entry whose admin account is gone says so', (tester) async {
      when(
        () => repository.getEntries(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Ok([_entry(1, actor: null)]));

      await pump(tester);

      expect(
        find.textContaining('by an account that no longer exists'),
        findsOneWidget,
      );
    });

    testWidgets('an empty log explains itself', (tester) async {
      when(
        () => repository.getEntries(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Ok([]));

      await pump(tester);

      expect(
        find.textContaining('Nothing has been recorded yet'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load shows an error', (tester) async {
      when(
        () => repository.getEntries(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
