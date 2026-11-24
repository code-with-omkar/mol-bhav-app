import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_subscriptions_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_subscriptions.dart';
import 'package:mol_bhav/features/admin/presentation/admin_subscriptions_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_subscriptions_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminSubscriptionsRepository {}

AdminSubscription _sub({
  String id = 's1',
  SubscriptionState status = SubscriptionState.active,
  String? name = 'Asha Patil',
  String? phone = '******3210',
  bool autoRenew = false,
  DateTime? cancelledAt,
}) => AdminSubscription(
  id: id,
  userId: 'u-$id',
  planCode: 'pro-monthly',
  status: status,
  startedAt: DateTime(2026, 10, 1),
  expiresAt: DateTime(2026, 11, 1),
  isAutoRenew: autoRenew,
  cancelledAt: cancelledAt,
  userPhone: phone,
  userName: name,
);

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.getSubscriptions(
        status: any(named: 'status'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok([_sub()]));
    when(() => repository.expire(any()))
        .thenAnswer((_) async => const Ok(null));
  });

  test('an API row is read; blank owner details are missing, not empty', () {
    final s = AdminSubscriptionsRepositoryImpl.parse({
      'id': 's9',
      'userId': 'u9',
      'planId': 'p1',
      'planCode': 'pro-yearly',
      'status': 'PendingPayment',
      'startedAtUtc': '2026-10-01T00:00:00+00:00',
      'expiresAtUtc': '2026-10-01T00:00:00+00:00',
      'isAutoRenew': true,
      'cancelledAtUtc': null,
      'userPhoneNumberMasked': '******3210',
      'userName': ' ',
    });

    expect(s.status, SubscriptionState.pendingPayment);
    expect(s.isAutoRenew, isTrue);
    expect(s.userName, isNull);
    expect(s.userLabel, '******3210');
    expect(s.canEnd, isFalse);
    expect(
      SubscriptionState.fromWire('SomethingNew'),
      SubscriptionState.expired,
    );
  });

  test('the owner is named by name, else masked phone, else not at all', () {
    expect(_sub().userLabel, 'Asha Patil');
    expect(_sub(name: null).userLabel, '******3210');
    expect(_sub(name: null, phone: null).userLabel, isNull);
  });

  test('only an active subscription can be ended', () {
    expect(_sub().canEnd, isTrue);
    for (final s in SubscriptionState.values.where(
      (s) => s != SubscriptionState.active,
    )) {
      expect(_sub(status: s).canEnd, isFalse);
    }
  });

  group('AdminSubscriptionsCubit', () {
    late AdminSubscriptionsCubit cubit;

    setUp(() => cubit = AdminSubscriptionsCubit(repository));
    tearDown(() => cubit.close());

    test('opens on the active subscriptions', () async {
      await cubit.load();

      expect(cubit.state.filter, SubscriptionState.active);
      verify(
        () => repository.getSubscriptions(
          status: SubscriptionState.active,
          page: 1,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).called(1);
    });

    test('a filter reloads, and All asks for every state', () async {
      await cubit.load();

      await cubit.setFilter(null);

      expect(cubit.state.filter, isNull);
      verify(
        () => repository.getSubscriptions(
          status: null,
          page: 1,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).called(1);
    });

    test('a full page offers more, added to the end', () async {
      final full = [
        for (var i = 0; i < AdminSubscriptionsCubit.pageSize; i++)
          _sub(id: 's$i'),
      ];
      when(
        () => repository.getSubscriptions(
          status: SubscriptionState.active,
          page: 1,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok(full));
      when(
        () => repository.getSubscriptions(
          status: SubscriptionState.active,
          page: 2,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok([_sub(id: 'last')]));
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(
        cubit.state.subscriptions,
        hasLength(AdminSubscriptionsCubit.pageSize + 1),
      );
      expect(cubit.state.hasMore, isFalse);
    });

    test('ending one asks the API, then rereads the list', () async {
      await cubit.load();

      final failure = await cubit.end(_sub());

      expect(failure, isNull);
      verify(() => repository.expire('s1')).called(1);
      verify(
        () => repository.getSubscriptions(
          status: SubscriptionState.active,
          page: 1,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).called(2);
    });

    test('a refusal is returned and the list is left alone', () async {
      await cubit.load();
      when(() => repository.expire(any())).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Already ended.')),
      );

      final failure = await cubit.end(_sub());

      expect(failure, isA<ServerFailure>());
      verify(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    test(
      'a subscription that is not active is never sent to be ended',
      () async {
        await cubit.load();

        await cubit.end(_sub(status: SubscriptionState.cancelled));

        verifyNever(() => repository.expire(any()));
      },
    );

    test('a failed first load is a failure', () async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });
  });

  group('AdminSubscriptionsPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminSubscriptionsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminSubscriptionsPage()),
      );
    }

    testWidgets('lists an active subscription with owner, plan and end date', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Asha Patil'), findsOneWidget);
      expect(find.textContaining('pro-monthly · Started'), findsOneWidget);
      expect(find.textContaining('Ends'), findsOneWidget);
      expect(find.text('End now'), findsOneWidget);
      // Chips: All + the four states, opening on Active.
      expect(find.text('Awaiting payment'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('an auto-renewing subscription says so', (tester) async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => Ok([_sub(autoRenew: true)]));

      await pump(tester);

      expect(find.textContaining('Renews automatically'), findsOneWidget);
    });

    testWidgets('an owner with no name shows the masked number, then unknown', (
      tester,
    ) async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _sub(id: 'a', name: null),
          _sub(id: 'b', name: null, phone: null),
        ]),
      );

      await pump(tester);

      expect(find.text('******3210'), findsOneWidget);
      expect(find.text('Unknown user'), findsOneWidget);
    });

    testWidgets('other states offer no End button and describe themselves', (
      tester,
    ) async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _sub(
            id: 'c',
            status: SubscriptionState.cancelled,
            cancelledAt: DateTime(2026, 10, 15),
          ),
          _sub(id: 'e', status: SubscriptionState.expired),
          _sub(id: 'p', status: SubscriptionState.pendingPayment),
        ]),
      );

      await pump(tester);

      expect(find.text('End now'), findsNothing);
      expect(find.textContaining('Cancelled Oct 15, 2026'), findsOneWidget);
      expect(find.textContaining('Ended Nov 1, 2026'), findsOneWidget);
      expect(find.textContaining('Waiting for the payment'), findsOneWidget);
    });

    testWidgets('ending asks first, and Cancel keeps the subscription', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('End now'));
      await tester.pumpAndSettle();
      expect(find.text('End this subscription?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.expire(any()));
    });

    testWidgets('confirming ends it and says so', (tester) async {
      await pump(tester);

      await tester.tap(find.text('End now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End subscription'));
      await tester.pumpAndSettle();

      verify(() => repository.expire('s1')).called(1);
      expect(find.text('Subscription ended.'), findsOneWidget);
    });

    testWidgets('a refusal is shown as the server wrote it', (tester) async {
      when(() => repository.expire(any())).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Only an active plan can end.')),
      );
      await pump(tester);

      await tester.tap(find.text('End now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End subscription'));
      await tester.pumpAndSettle();

      expect(find.text('Only an active plan can end.'), findsOneWidget);
    });

    testWidgets('picking a state chip loads that state', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Expired'));
      await tester.pump();

      verify(
        () => repository.getSubscriptions(
          status: SubscriptionState.expired,
          page: 1,
          pageSize: AdminSubscriptionsCubit.pageSize,
        ),
      ).called(1);
    });

    testWidgets('an empty list says so', (tester) async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Ok([]));

      await pump(tester);

      expect(find.text('No subscriptions here.'), findsOneWidget);
    });

    testWidgets('a failed load shows an error', (tester) async {
      when(
        () => repository.getSubscriptions(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
