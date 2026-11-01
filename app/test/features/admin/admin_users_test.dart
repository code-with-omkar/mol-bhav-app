import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_users_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_users.dart';
import 'package:mol_bhav/features/admin/presentation/admin_user_detail_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_user_detail_page.dart';
import 'package:mol_bhav/features/admin/presentation/admin_users_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_users_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminUsersRepository {}

Map<String, dynamic> _userJson({
  String id = 'u1',
  String? name = 'Asha',
  String role = 'User',
  String status = 'Active',
  String tier = 'Free',
}) => {
  'id': id,
  'phoneNumber': '+919876543210',
  'displayName': name,
  'role': role,
  'status': status,
  'subscriptionTier': tier,
  'state': 'MH',
  'district': 'Kolhapur',
  'businessType': 'Farmer',
  'lastLoginAtUtc': '2026-10-16T10:00:00+00:00',
  'createdAtUtc': '2026-09-01T10:00:00+00:00',
};

AdminUser _user(
  String id, {
  String? name,
  bool suspended = false,
  bool admin = false,
}) => AdminUsersRepositoryImpl.parseUser(
  _userJson(
    id: id,
    name: name,
    status: suspended ? 'Suspended' : 'Active',
    role: admin ? 'Admin' : 'User',
  ),
);

AdminUserDetail _detail({bool suspended = false, bool admin = false}) =>
    AdminUsersRepositoryImpl.parseDetail({
      'user': _userJson(
        status: suspended ? 'Suspended' : 'Active',
        role: admin ? 'Admin' : 'User',
        tier: 'Pro',
      ),
      'categories': ['agriculture'],
      'latestSubscription': {
        'planName': 'Pro Monthly',
        'status': 'Active',
        'expiresAtUtc': '2026-12-01T00:00:00+00:00',
      },
      'ticketsTotal': 3,
      'ticketsOpen': 1,
    });

void main() {
  group('parsing', () {
    test('a user', () {
      final u = AdminUsersRepositoryImpl.parseUser(
        _userJson(role: 'Admin', status: 'Suspended', tier: 'Pro'),
      );

      expect(u.isAdmin, isTrue);
      expect(u.isSuspended, isTrue);
      expect(u.isPro, isTrue);
      expect(u.place, 'Kolhapur, MH');
      expect(u.title, 'Asha');
    });

    test('the phone number stands in for a missing name', () {
      expect(_user('u1', name: null).title, '+919876543210');
      expect(_user('u1', name: '  ').title, '+919876543210');
    });

    test('a detail with and without a subscription', () {
      final d = _detail();
      expect(d.categories, ['agriculture']);
      expect(d.latestSubscription?.planName, 'Pro Monthly');
      expect(d.ticketsOpen, 1);

      final none = AdminUsersRepositoryImpl.parseDetail({
        'user': _userJson(),
        'categories': <String>[],
        'ticketsTotal': 0,
        'ticketsOpen': 0,
      });
      expect(none.latestSubscription, isNull);
    });

    test('the filter maps to the API status', () {
      expect(UserListFilter.all.wire, isNull);
      expect(UserListFilter.active.wire, 'Active');
      expect(UserListFilter.suspended.wire, 'Suspended');
    });
  });

  group('AdminUsersCubit', () {
    late _MockRepository repository;
    late AdminUsersCubit cubit;

    List<AdminUser> page(int n, {int from = 0}) => [
      for (var i = 0; i < n; i++)
        _user('u${from + i}', name: 'User ${from + i}'),
    ];

    void serve({
      String? search,
      UserListFilter? filter,
      int? pageNo,
      required List<AdminUser> users,
    }) => when(
      () => repository.getUsers(
        search: search ?? any(named: 'search'),
        filter: filter ?? any(named: 'filter'),
        page: pageNo ?? any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok(users));

    setUp(() {
      repository = _MockRepository();
      cubit = AdminUsersCubit(repository);
      registerFallbackValue(UserListFilter.all);
    });

    tearDown(() => cubit.close());

    test('loads the first page; a full page means more may follow', () async {
      serve(users: page(AdminUsersCubit.pageSize));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.users, hasLength(AdminUsersCubit.pageSize));
      expect(cubit.state.hasMore, isTrue);
    });

    test('a short page ends the list', () async {
      serve(users: page(3));

      await cubit.load();

      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore();
      verify(
        () => repository.getUsers(
          search: any(named: 'search'),
          filter: any(named: 'filter'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    test('loading more appends the next page', () async {
      serve(pageNo: 1, users: page(AdminUsersCubit.pageSize));
      serve(pageNo: 2, users: page(5, from: 100));
      await cubit.load();

      await cubit.loadMore();

      expect(cubit.state.users, hasLength(AdminUsersCubit.pageSize + 5));
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.loadingMore, isFalse);
    });

    test(
      'a failed "load more" keeps the users and allows another try',
      () async {
        serve(pageNo: 1, users: page(AdminUsersCubit.pageSize));
        await cubit.load();
        when(
          () => repository.getUsers(
            search: any(named: 'search'),
            filter: any(named: 'filter'),
            page: 2,
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => const Err(NetworkFailure()));

        await cubit.loadMore();

        expect(cubit.state.users, hasLength(AdminUsersCubit.pageSize));
        expect(cubit.state.hasMore, isTrue);
        expect(cubit.state.loadingMore, isFalse);
      },
    );

    test('searching starts again from page 1 with the trimmed text', () async {
      serve(users: page(2));
      await cubit.load();

      await cubit.search('  9876 ');

      expect(cubit.state.query, '9876');
      verify(
        () => repository.getUsers(
          search: '9876',
          filter: UserListFilter.all,
          page: 1,
          pageSize: AdminUsersCubit.pageSize,
        ),
      ).called(1);
    });

    test(
      'changing the filter reloads; picking the same one does not',
      () async {
        serve(users: page(2));
        await cubit.load();

        await cubit.setFilter(UserListFilter.suspended);
        await cubit.setFilter(UserListFilter.suspended);

        expect(cubit.state.filter, UserListFilter.suspended);
        verify(
          () => repository.getUsers(
            search: any(named: 'search'),
            filter: UserListFilter.suspended,
            page: 1,
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
    );

    test('a failed first load reports the failure', () async {
      when(
        () => repository.getUsers(
          search: any(named: 'search'),
          filter: any(named: 'filter'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
      expect(cubit.state.failure, const NetworkFailure());
    });
  });

  group('AdminUserDetailCubit', () {
    late _MockRepository repository;
    late AdminUserDetailCubit cubit;

    setUp(() {
      repository = _MockRepository();
      cubit = AdminUserDetailCubit(repository);
    });

    tearDown(() => cubit.close());

    test('suspending reloads the user and marks the list stale', () async {
      when(() => repository.getUser('u1'))
          .thenAnswer((_) async => Ok(_detail(suspended: true)));
      when(() => repository.setSuspended('u1', suspend: true))
          .thenAnswer((_) async => const Ok(null));

      await cubit.setSuspended('u1', suspend: true);

      expect(cubit.state.changed, isTrue);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.detail.data?.user.isSuspended, isTrue);
      verify(() => repository.setSuspended('u1', suspend: true)).called(1);
    });

    test(
      'a refusal is kept for the page to show, and nothing changed',
      () async {
        when(() => repository.setSuspended('u1', suspend: true)).thenAnswer(
          (_) async => const Err(
            ServerFailure(
              statusCode: 403,
              message: 'An admin account cannot be suspended.',
            ),
          ),
        );

        await cubit.setSuspended('u1', suspend: true);

        expect(cubit.state.changed, isFalse);
        expect(cubit.state.busy, isFalse);
        expect(cubit.state.actionFailure, isA<ServerFailure>());

        cubit.failureShown();
        expect(cubit.state.actionFailure, isNull);
      },
    );
  });

  group('AdminUsersPage', () {
    late _MockRepository repository;

    setUp(() {
      repository = _MockRepository();
      registerFallbackValue(UserListFilter.all);
    });

    void serveUsers(List<AdminUser> users) => when(
      () => repository.getUsers(
        search: any(named: 'search'),
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok(users));

    Future<AdminUsersCubit> pump(WidgetTester tester) async {
      final cubit = AdminUsersCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminUsersCubit>.value(
          value: cubit,
          child: const AdminUsersPage(),
        ),
      );
      return cubit;
    }

    testWidgets('lists users with their badges', (tester) async {
      serveUsers([
        _user('u1', name: 'Asha', suspended: true),
        _user('u2', name: 'Ravi', admin: true),
      ]);
      await pump(tester);

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('Suspended'), findsNWidgets(2)); // filter chip + badge
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('says so when nobody matches', (tester) async {
      serveUsers(const []);
      await pump(tester);

      expect(find.text('No users match.'), findsOneWidget);
    });

    testWidgets('picking a filter chip filters the list', (tester) async {
      serveUsers([_user('u1', name: 'Asha')]);
      await pump(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pump();

      verify(
        () => repository.getUsers(
          search: any(named: 'search'),
          filter: UserListFilter.suspended,
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    testWidgets('typing searches after a short pause', (tester) async {
      serveUsers([_user('u1', name: 'Asha')]);
      await pump(tester);

      await tester.enterText(find.byType(TextField), '9876');
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => repository.getUsers(
          search: '9876',
          filter: any(named: 'filter'),
          page: 1,
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });
  });

  group('AdminUserDetailPage', () {
    late _MockRepository repository;

    setUp(() => repository = _MockRepository());

    Future<void> pump(WidgetTester tester, AdminUserDetail detail) async {
      when(() => repository.getUser('u1')).thenAnswer((_) async => Ok(detail));
      final cubit = AdminUserDetailCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('u1');
      await tester.pumpApp(
        BlocProvider<AdminUserDetailCubit>.value(
          value: cubit,
          child: const AdminUserDetailPage(userId: 'u1'),
        ),
      );
    }

    testWidgets('shows the profile, subscription and tickets', (tester) async {
      await pump(tester, _detail());

      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('Kolhapur, MH'), findsOneWidget);
      expect(find.text('agriculture'), findsOneWidget);
      expect(find.textContaining('Pro Monthly'), findsOneWidget);
      expect(find.text('3 total · 1 open'), findsOneWidget);
    });

    testWidgets('suspending asks first, then does it', (tester) async {
      when(() => repository.setSuspended('u1', suspend: true))
          .thenAnswer((_) async => const Ok(null));
      await pump(tester, _detail());

      await tester.scrollUntilVisible(find.text('Suspend account'), 200);
      await tester.tap(find.text('Suspend account'));
      await tester.pumpAndSettle();
      expect(find.text('Suspend this account?'), findsOneWidget);
      verifyNever(() => repository.setSuspended('u1', suspend: true));

      await tester.tap(find.text('Suspend'));
      await tester.pumpAndSettle();

      verify(() => repository.setSuspended('u1', suspend: true)).called(1);
    });

    testWidgets('cancelling the confirmation changes nothing', (tester) async {
      await pump(tester, _detail());

      await tester.scrollUntilVisible(find.text('Suspend account'), 200);
      await tester.tap(find.text('Suspend account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(
        () => repository.setSuspended(any(), suspend: any(named: 'suspend')),
      );
    });

    testWidgets('a suspended user is reinstated with one tap', (tester) async {
      when(() => repository.setSuspended('u1', suspend: false))
          .thenAnswer((_) async => const Ok(null));
      await pump(tester, _detail(suspended: true));

      await tester.scrollUntilVisible(find.text('Reinstate account'), 200);
      await tester.tap(find.text('Reinstate account'));
      await tester.pumpAndSettle();

      verify(() => repository.setSuspended('u1', suspend: false)).called(1);
    });

    testWidgets('an admin account has no suspend button', (tester) async {
      await pump(tester, _detail(admin: true));

      expect(find.text('Suspend account'), findsNothing);
      expect(find.text('Reinstate account'), findsNothing);
    });
  });
}
