import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_billing_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_billing.dart';
import 'package:mol_bhav/features/admin/presentation/admin_coupons_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_coupons_page.dart';
import 'package:mol_bhav/features/admin/presentation/admin_plans_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_plans_page.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminBillingRepository {}

/// Records what the app sends, and answers 204.
class _Capture implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

const _monthly = AdminPlan(
  id: 'p1',
  code: 'pro-monthly',
  name: 'Pro monthly',
  price: 149,
  currency: 'INR',
  period: PlanPeriod.monthly,
  isActive: true,
);

const _yearly = AdminPlan(
  id: 'p2',
  code: 'pro-yearly',
  name: 'Pro yearly',
  price: 1499.5,
  currency: 'INR',
  period: PlanPeriod.yearly,
  isActive: false,
);

AdminCoupon _coupon({
  String id = 'k1',
  String code = 'DIWALI20',
  CouponKind kind = CouponKind.percent,
  int value = 20,
  int? maxUses = 100,
  int used = 12,
  DateTime? validTo,
  bool isActive = true,
  String? plan,
  int min = 0,
}) => AdminCoupon(
  id: id,
  code: code,
  kind: kind,
  value: value,
  maxUses: maxUses,
  usesCount: used,
  validFrom: DateTime(2026, 11, 1),
  validTo: validTo,
  planCode: plan,
  minAmountPaise: min,
  isActive: isActive,
);

void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(const PlanDraft());
    registerFallbackValue(const CouponDraft());
    registerFallbackValue(const CouponEdit(isActive: true));
  });

  setUp(() {
    repository = _MockRepository();
    when(() => repository.getPlans())
        .thenAnswer((_) async => const Ok([_monthly, _yearly]));
    when(
      () => repository.getCoupons(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok([_coupon()]));
    when(() => repository.createPlan(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.updatePlan(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.createCoupon(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.updateCoupon(any(), any()))
        .thenAnswer((_) async => const Ok(null));
  });

  group('money', () {
    test('a price is whole rupees or up to two decimals', () {
      expect(parseRupees('149'), 149);
      expect(parseRupees(' 149.5 '), 149.5);
      expect(parseRupees('149.50'), 149.5);
      expect(parseRupees(''), isNull);
      expect(parseRupees('1,49'), isNull);
      expect(parseRupees('149.505'), isNull);
      expect(parseRupees('-5'), isNull);
      expect(parseRupees('abc'), isNull);
    });

    test('rupees become paise without drifting', () {
      expect(rupeesToPaise(50), 5000);
      expect(rupeesToPaise(49.9), 4990);
      expect(rupeesToPaise(19.99), 1999);
      expect(rupeesToPaise(0.07), 7);
      expect(rupeesToPaise(1.15), 115);
    });
  });

  group('plan form rules', () {
    const valid = PlanDraft(
      code: 'pro-monthly',
      name: 'Pro monthly',
      price: '149',
    );

    test('a complete new plan has no problems', () {
      expect(planProblems(valid, isNew: true), isEmpty);
    });

    test('the code matters only for a new plan', () {
      const bad = PlanDraft(code: 'pro monthly!', name: 'x', price: '1');
      expect(planProblems(bad, isNew: true), {PlanProblem.codeInvalid});
      expect(planProblems(bad, isNew: false), isEmpty);
      expect(planProblems(valid.copyWith(code: 'a' * 33), isNew: true), {
        PlanProblem.codeInvalid,
      });
    });

    test('a name is required and limited; a price must be a price', () {
      expect(planProblems(valid.copyWith(name: ' '), isNew: false), {
        PlanProblem.nameInvalid,
      });
      expect(planProblems(valid.copyWith(name: 'n' * 101), isNew: false), {
        PlanProblem.nameInvalid,
      });
      expect(planProblems(valid.copyWith(price: ''), isNew: false), {
        PlanProblem.priceInvalid,
      });
      expect(planProblems(valid.copyWith(price: '0'), isNew: false), isEmpty);
    });

    test('an existing plan starts the form with its own values', () {
      final draft = PlanDraft.from(_yearly);

      expect(draft.code, 'pro-yearly');
      expect(draft.price, '1499.50');
      expect(draft.period, PlanPeriod.yearly);
      expect(draft.isActive, isFalse);
      expect(PlanDraft.from(_monthly).price, '149');
    });
  });

  group('coupon form rules', () {
    final valid = CouponDraft(
      code: 'DIWALI20',
      value: '20',
      startsOn: DateTime(2026, 11, 1),
    );

    test('a complete percent coupon has no problems', () {
      expect(couponProblems(valid), isEmpty);
    });

    test('a percent is a whole number from 1 to 100', () {
      expect(couponProblems(valid.copyWith(value: '0')), {
        CouponProblem.valueInvalid,
      });
      expect(couponProblems(valid.copyWith(value: '101')), {
        CouponProblem.valueInvalid,
      });
      expect(couponProblems(valid.copyWith(value: '12.5')), {
        CouponProblem.valueInvalid,
      });
      expect(couponProblems(valid.copyWith(value: '100')), isEmpty);
    });

    test('an amount is typed in rupees and kept in paise', () {
      final fixed = valid.copyWith(kind: CouponKind.fixed, value: '50');

      expect(couponProblems(fixed), isEmpty);
      expect(fixed.discountValue, 5000);
      expect(fixed.copyWith(value: '49.50').discountValue, 4950);
      // A fixed amount may exceed 100: only a percent is capped.
      expect(couponProblems(fixed.copyWith(value: '500')), isEmpty);
      expect(couponProblems(fixed.copyWith(value: '0')), {
        CouponProblem.valueInvalid,
      });
    });

    test('the minimum price is optional, in rupees, kept in paise', () {
      expect(valid.minAmountPaise, 0);
      expect(valid.copyWith(minAmount: '100').minAmountPaise, 10000);
      expect(couponProblems(valid.copyWith(minAmount: '1,00')), {
        CouponProblem.minAmountInvalid,
      });
    });

    test('the use limit is empty (none) or 1 or more', () {
      expect(valid.maxUsesValue, isNull);
      expect(couponProblems(valid.copyWith(maxUses: '0')), {
        CouponProblem.maxUsesInvalid,
      });
      expect(couponProblems(valid.copyWith(maxUses: '50')), isEmpty);
    });

    test('a code is letters, digits, - or _', () {
      expect(couponProblems(valid.copyWith(code: '')), {
        CouponProblem.codeInvalid,
      });
      expect(couponProblems(valid.copyWith(code: 'DI WALI')), {
        CouponProblem.codeInvalid,
      });
      expect(couponProblems(valid.copyWith(code: 'DIWALI-20_B')), isEmpty);
    });

    test('a start is needed; the end may not come before it', () {
      expect(couponProblems(valid.copyWith(startsOn: () => null)), {
        CouponProblem.startMissing,
      });
      expect(
        couponProblems(valid.copyWith(endsOn: () => DateTime(2026, 10, 31))),
        {CouponProblem.endBeforeStart},
      );
      expect(
        couponProblems(valid.copyWith(endsOn: () => DateTime(2026, 11, 1))),
        isEmpty,
      );
    });

    test('an edit cannot set the limit below what is already used', () {
      final coupon = _coupon();

      expect(
        couponEditProblems(
          const CouponEdit(isActive: true, maxUses: '5'),
          coupon,
        ),
        {CouponProblem.maxUsesInvalid},
      );
      expect(
        couponEditProblems(
          const CouponEdit(isActive: true, maxUses: '12'),
          coupon,
        ),
        isEmpty,
      );
      // Empty means no limit.
      expect(
        couponEditProblems(const CouponEdit(isActive: true), coupon),
        isEmpty,
      );
      expect(
        couponEditProblems(
          CouponEdit(isActive: true, endsOn: DateTime(2026, 10, 1)),
          coupon,
        ),
        {CouponProblem.endBeforeStart},
      );
    });

    test('a coupon knows when it has expired or run out', () {
      expect(
        _coupon(validTo: DateTime(2026, 1, 1)).isExpired(DateTime(2026, 6)),
        isTrue,
      );
      expect(_coupon().isExpired(DateTime(2030)), isFalse);
      expect(_coupon(used: 100).isUsedUp, isTrue);
      expect(_coupon(maxUses: null, used: 9999).isUsedUp, isFalse);
    });
  });

  group('what is sent', () {
    late _Capture capture;
    late AdminBillingRepositoryImpl impl;

    setUp(() {
      capture = _Capture();
      impl = AdminBillingRepositoryImpl(Dio()..httpClientAdapter = capture);
    });

    test(
      'a fixed coupon goes out in paise, with day boundaries in UTC',
      () async {
        final draft = CouponDraft(
          code: ' DIWALI50 ',
          kind: CouponKind.fixed,
          value: '50',
          maxUses: '100',
          startsOn: DateTime(2026, 11, 1),
          endsOn: DateTime(2026, 11, 30),
          planCode: 'pro-yearly',
          minAmount: '299',
        );

        await impl.createCoupon(draft);

        final body = capture.last!.data as Map<String, dynamic>;
        expect(capture.last!.path, '/admin/coupons');
        expect(body['code'], 'DIWALI50');
        expect(body['discountType'], 'Fixed');
        expect(body['discountValue'], 5000);
        expect(body['maxUses'], 100);
        expect(body['minAmountPaise'], 29900);
        expect(body['applicablePlanCode'], 'pro-yearly');
        expect(
          body['validFrom'],
          DateTime(2026, 11, 1).toUtc().toIso8601String(),
        );
        expect(
          body['validTo'],
          DateTime(2026, 11, 30, 23, 59, 59).toUtc().toIso8601String(),
        );
      },
    );

    test(
      'a percent coupon goes out as typed, with no limits as nulls',
      () async {
        await impl.createCoupon(
          CouponDraft(
            code: 'OPEN10',
            value: '10',
            startsOn: DateTime(2026, 11, 1),
          ),
        );

        final body = capture.last!.data as Map<String, dynamic>;
        expect(body['discountType'], 'Percent');
        expect(body['discountValue'], 10);
        expect(body['maxUses'], isNull);
        expect(body['validTo'], isNull);
        expect(body['applicablePlanCode'], isNull);
        expect(body['minAmountPaise'], 0);
      },
    );

    test('a coupon edit replaces the three editable fields', () async {
      await impl.updateCoupon(
        'k1',
        CouponEdit(isActive: false, endsOn: DateTime(2026, 12, 31)),
      );

      final body = capture.last!.data as Map<String, dynamic>;
      expect(capture.last!.method, 'PUT');
      expect(capture.last!.path, '/admin/coupons/k1');
      expect(body['isActive'], false);
      expect(body['maxUses'], isNull);
      expect(
        body['validTo'],
        DateTime(2026, 12, 31, 23, 59, 59).toUtc().toIso8601String(),
      );
    });

    test('a new plan goes out in rupees, in INR', () async {
      await impl.createPlan(
        const PlanDraft(
          code: ' pro-yearly ',
          name: ' Pro yearly ',
          price: '1499.50',
          period: PlanPeriod.yearly,
        ),
      );

      final body = capture.last!.data as Map<String, dynamic>;
      expect(body, {
        'code': 'pro-yearly',
        'name': 'Pro yearly',
        'price': 1499.5,
        'currency': 'INR',
        'billingPeriod': 'Yearly',
      });
    });

    test('a plan edit sends name, price and on/off, never the code', () async {
      await impl.updatePlan(
        'p1',
        const PlanDraft(
          code: 'ignored',
          name: 'Pro monthly',
          price: '199',
          isActive: false,
        ),
      );

      final body = capture.last!.data as Map<String, dynamic>;
      expect(capture.last!.path, '/admin/billing/plans/p1');
      expect(body, {'name': 'Pro monthly', 'price': 199.0, 'isActive': false});
    });
  });

  test('API rows are read', () {
    final plan = AdminBillingRepositoryImpl.parsePlan({
      'id': 'p9',
      'code': 'pro-yearly',
      'name': 'Pro yearly',
      'price': 1499.5,
      'currency': 'INR',
      'billingPeriod': 'Yearly',
      'isActive': true,
    });
    final coupon = AdminBillingRepositoryImpl.parseCoupon({
      'id': 'k9',
      'code': 'FLAT50',
      'discountType': 'Fixed',
      'discountValue': 5000,
      'maxUses': null,
      'usesCount': 3,
      'validFrom': '2026-11-01T00:00:00+00:00',
      'validTo': null,
      'applicablePlanCode': null,
      'minAmountPaise': 0,
      'isActive': true,
    });

    expect(plan.price, 1499.5);
    expect(plan.period, PlanPeriod.yearly);
    expect(coupon.kind, CouponKind.fixed);
    expect(coupon.value, 5000);
    expect(coupon.maxUses, isNull);
    expect(coupon.validTo, isNull);
    expect(PlanPeriod.fromWire('Weekly'), PlanPeriod.monthly);
  });

  group('AdminPlansCubit', () {
    late AdminPlansCubit cubit;

    setUp(() => cubit = AdminPlansCubit(repository));
    tearDown(() => cubit.close());

    test('loads the plans', () async {
      await cubit.load();

      expect(cubit.state.data, [_monthly, _yearly]);
    });

    test('a saved plan rereads the list and reports no failure', () async {
      await cubit.load();

      final failure = await cubit.update(
        'p1',
        const PlanDraft(name: 'x', price: '1'),
      );

      expect(failure, isNull);
      verify(() => repository.getPlans()).called(2);
    });

    test('a refused plan reports why and leaves the list alone', () async {
      await cubit.load();
      when(() => repository.createPlan(any())).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Plan code already used.')),
      );

      final failure = await cubit.create(
        const PlanDraft(code: 'x', name: 'x', price: '1'),
      );

      expect(failure, isA<ServerFailure>());
      verify(() => repository.getPlans()).called(1);
    });
  });

  group('AdminCouponsCubit', () {
    late AdminCouponsCubit cubit;

    setUp(() => cubit = AdminCouponsCubit(repository));
    tearDown(() => cubit.close());

    test('loads the coupons and the plans to pick from', () async {
      await cubit.load();

      expect(cubit.state.coupons, hasLength(1));
      expect(cubit.state.plans, hasLength(2));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a failed plan list still shows the coupons', () async {
      when(() => repository.getPlans())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.plans, isEmpty);
    });

    test('a full page offers more, added to the end', () async {
      final full = [
        for (var i = 0; i < AdminCouponsCubit.pageSize; i++)
          _coupon(id: 'k$i', code: 'C$i'),
      ];
      when(
        () => repository.getCoupons(
          page: 1,
          pageSize: AdminCouponsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok(full));
      when(
        () => repository.getCoupons(
          page: 2,
          pageSize: AdminCouponsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok([_coupon(id: 'last', code: 'LAST')]));
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.coupons, hasLength(AdminCouponsCubit.pageSize + 1));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a created coupon rereads the list; a refusal reports why', () async {
      await cubit.load();

      expect(
        await cubit.create(
          CouponDraft(code: 'X', value: '5', startsOn: DateTime(2026)),
        ),
        isNull,
      );
      verify(
        () => repository.getCoupons(
          page: 1,
          pageSize: AdminCouponsCubit.pageSize,
        ),
      ).called(2);

      when(() => repository.createCoupon(any())).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Coupon code already used.')),
      );
      expect(
        await cubit.create(
          CouponDraft(code: 'X', value: '5', startsOn: DateTime(2026)),
        ),
        isA<ServerFailure>(),
      );
    });
  });

  group('AdminPlansPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminPlansCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminPlansPage()),
      );
    }

    testWidgets('lists each plan with its price and whether it is on', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Pro monthly'), findsOneWidget);
      expect(find.text('₹149 / month'), findsOneWidget);
      expect(find.text('₹1,499.50 / year'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('a new plan is added from the sheet', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New plan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'pro-quarter');
      await tester.enterText(find.byType(TextField).at(1), 'Pro quarterly');
      await tester.enterText(find.byType(TextField).at(2), '399');
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.createPlan(captureAny())).captured.single
              as PlanDraft;
      expect(saved.code, 'pro-quarter');
      expect(saved.priceValue, 399);
      // The sheet closes on success.
      expect(find.text('Save plan'), findsNothing);
    });

    testWidgets('an incomplete plan shows what is wrong and sends nothing', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save plan'));
      await tester.pump();

      expect(find.textContaining('Use a price like'), findsOneWidget);
      verifyNever(() => repository.createPlan(any()));
    });

    testWidgets('a refused save stays open and says why', (tester) async {
      when(() => repository.createPlan(any())).thenAnswer(
        (_) async =>
            const Err(ServerFailure(message: 'Plan code already used.')),
      );
      await pump(tester);

      await tester.tap(find.text('New plan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'pro-monthly');
      await tester.enterText(find.byType(TextField).at(1), 'Dup');
      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      expect(find.text('Plan code already used.'), findsOneWidget);
      expect(find.text('Save plan'), findsOneWidget);
    });

    testWidgets('an existing plan cannot have its code changed', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Pro monthly'));
      await tester.pumpAndSettle();

      expect(find.text('Edit plan'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).enabled,
        isFalse,
      );
      await tester.enterText(find.byType(TextField).at(2), '199');
      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.updatePlan('p1', captureAny()))
                  .captured
                  .single
              as PlanDraft;
      expect(saved.priceValue, 199);
    });

    testWidgets('a failed load shows an error', (tester) async {
      when(() => repository.getPlans())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });

  group('AdminCouponsPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminCouponsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminCouponsPage()),
      );
    }

    testWidgets('lists a coupon with its discount, plan and use count', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('DIWALI20'), findsOneWidget);
      expect(find.textContaining('20% off'), findsOneWidget);
      expect(find.textContaining('Any plan'), findsOneWidget);
      expect(find.textContaining('Used 12 of 100'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('a fixed amount shows in rupees and a minimum price shows', (
      tester,
    ) async {
      when(
        () => repository.getCoupons(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _coupon(
            code: 'FLAT50',
            kind: CouponKind.fixed,
            value: 5000,
            maxUses: null,
            plan: 'pro-yearly',
            min: 29900,
          ),
        ]),
      );

      await pump(tester);

      expect(find.textContaining('₹50.00 off'), findsOneWidget);
      expect(find.textContaining('pro-yearly'), findsOneWidget);
      expect(find.textContaining('from ₹299.00'), findsOneWidget);
      expect(find.textContaining('Used 12'), findsOneWidget);
    });

    testWidgets('a switched-off, expired or used-up coupon says so', (
      tester,
    ) async {
      when(
        () => repository.getCoupons(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _coupon(id: 'a', code: 'OFF', isActive: false),
          _coupon(id: 'b', code: 'OLD', validTo: DateTime(2020)),
          _coupon(id: 'c', code: 'DONE', used: 100),
        ]),
      );

      await pump(tester);

      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Used up'), findsOneWidget);
    });

    testWidgets('a new fixed coupon is typed in rupees and saved', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New coupon'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'FLAT50');
      await tester.tap(find.text('Amount off'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), '50');
      await tester.ensureVisible(find.text('Save coupon'));
      await tester.tap(find.text('Save coupon'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.createCoupon(captureAny())).captured.single
              as CouponDraft;
      expect(saved.kind, CouponKind.fixed);
      expect(saved.discountValue, 5000);
      expect(find.text('Save coupon'), findsNothing);
    });

    testWidgets('a percent above 100 is refused before it is sent', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New coupon'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'TOOMUCH');
      await tester.enterText(find.byType(TextField).at(1), '150');
      await tester.ensureVisible(find.text('Save coupon'));
      await tester.tap(find.text('Save coupon'));
      await tester.pump();

      expect(find.text('Use a whole number from 1 to 100'), findsOneWidget);
      verifyNever(() => repository.createCoupon(any()));
    });

    testWidgets('editing switches a coupon off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('DIWALI20'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.ensureVisible(find.text('Save coupon'));
      await tester.tap(find.text('Save coupon'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.updateCoupon('k1', captureAny()))
                  .captured
                  .single
              as CouponEdit;
      expect(saved.isActive, isFalse);
    });

    testWidgets('a use limit below what is already used is refused', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('DIWALI20'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '5');
      await tester.ensureVisible(find.text('Save coupon'));
      await tester.tap(find.text('Save coupon'));
      await tester.pump();

      expect(
        find.textContaining('not below the 12 already used'),
        findsOneWidget,
      );
      verifyNever(() => repository.updateCoupon(any(), any()));
    });

    testWidgets('an empty list says so', (tester) async {
      when(
        () => repository.getCoupons(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Ok([]));

      await pump(tester);

      expect(find.text('No coupons yet.'), findsOneWidget);
    });
  });
}
