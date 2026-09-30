import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/billing/domain/billing.dart';
import 'package:mol_bhav/features/billing/presentation/cubit/coupon_cubit.dart';

class _MockRepo extends Mock implements BillingRepository {}

const _valid = CouponValidation(
  isValid: true,
  originalAmountPaise: 49900,
  discountPaise: 4990,
  finalAmountPaise: 44910,
);

const _unusable = CouponValidation(
  isValid: false,
  originalAmountPaise: 49900,
  discountPaise: 0,
  finalAmountPaise: 49900,
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  CouponCubit build() =>
      CouponCubit(repo)..debounce = const Duration(milliseconds: 10);

  blocTest<CouponCubit, CouponState>(
    'rapid typing collapses into one request for the last input',
    setUp: () =>
        when(() => repo.validateCoupon(any(), any()))
            .thenAnswer((_) async => const Ok(_valid)),
    build: build,
    act: (c) {
      c
        ..onCodeChanged('l', 'pro-monthly')
        ..onCodeChanged('la', 'pro-monthly')
        ..onCodeChanged('launch50', 'pro-monthly');
    },
    wait: const Duration(milliseconds: 50),
    expect: () => const [
      CouponValidating('LAUNCH50'),
      CouponValid('LAUNCH50', _valid),
    ],
    verify: (_) =>
        verify(() => repo.validateCoupon('LAUNCH50', 'pro-monthly')).called(1),
  );

  blocTest<CouponCubit, CouponState>(
    'an answer for an older input is dropped',
    setUp: () {
      final slow = Completer<Result<CouponValidation>>();
      when(() => repo.validateCoupon('OLD', any()))
          .thenAnswer((_) => slow.future);
      when(() => repo.validateCoupon('NEW', any()))
          .thenAnswer((_) async => const Ok(_unusable));
      // The stale answer arrives after the newer one.
      Future<void>.delayed(
        const Duration(milliseconds: 60),
        () => slow.complete(const Ok(_valid)),
      );
    },
    build: build,
    act: (c) async {
      c.onCodeChanged('old', 'pro-monthly');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      c.onCodeChanged('new', 'pro-monthly');
    },
    wait: const Duration(milliseconds: 100),
    expect: () => const [
      CouponValidating('OLD'),
      CouponValidating('NEW'),
      CouponInvalid('NEW'),
    ],
  );

  blocTest<CouponCubit, CouponState>(
    'an unusable coupon is invalid; a failed check carries the failure',
    setUp: () {
      when(() => repo.validateCoupon('BAD', any()))
          .thenAnswer((_) async => const Ok(_unusable));
      when(() => repo.validateCoupon('OFFLINE', any()))
          .thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (c) async {
      c.onCodeChanged('bad', 'pro-monthly');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      c.onCodeChanged('offline', 'pro-monthly');
    },
    wait: const Duration(milliseconds: 50),
    expect: () => const [
      CouponValidating('BAD'),
      CouponInvalid('BAD'),
      CouponValidating('OFFLINE'),
      CouponInvalid('OFFLINE', failure: NetworkFailure()),
    ],
  );

  blocTest<CouponCubit, CouponState>(
    'clearing the field resets without a request',
    build: build,
    act: (c) => c
      ..onCodeChanged('launch50', 'pro-monthly')
      ..onCodeChanged('  ', 'pro-monthly'),
    wait: const Duration(milliseconds: 30),
    expect: () => const [CouponInitial()],
    verify: (_) => verifyNever(() => repo.validateCoupon(any(), any())),
  );
}
