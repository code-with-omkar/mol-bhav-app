import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/billing.dart';

/// Billing endpoints (the envelope is unwrapped by `EnvelopeInterceptor`):
///
/// - `GET  /billing/plans` → `[PlanResponse]`
/// - `POST /billing/subscribe` → `SubscribeResponseDto`
/// - `POST /billing/coupons/validate` → `CouponValidationDto`
/// - `GET  /billing/subscription` → `SubscriptionResponse`, 404 when none
/// - `POST /billing/subscription/activate` → `SubscriptionResponse`
/// - `POST /billing/subscription/cancel` → 204
abstract interface class BillingRemoteDataSource {
  Future<List<dynamic>> getPlans();

  Future<Map<String, dynamic>> subscribe(Map<String, dynamic> body);

  Future<Map<String, dynamic>> validateCoupon(Map<String, dynamic> body);

  /// `null` for the API's 404 "no subscription".
  Future<Map<String, dynamic>?> getSubscription();

  Future<Map<String, dynamic>> activate(Map<String, dynamic> body);

  Future<void> cancel();
}

@LazySingleton(as: BillingRemoteDataSource)
class DioBillingRemoteDataSource implements BillingRemoteDataSource {
  DioBillingRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getPlans() async =>
      (await _dio.get<List<dynamic>>('/billing/plans')).data!;

  @override
  Future<Map<String, dynamic>> subscribe(Map<String, dynamic> body) async =>
      (await _dio.post<Map<String, dynamic>>(
        '/billing/subscribe',
        data: body,
      )).data!;

  @override
  Future<Map<String, dynamic>> validateCoupon(
    Map<String, dynamic> body,
  ) async => (await _dio.post<Map<String, dynamic>>(
    '/billing/coupons/validate',
    data: body,
  )).data!;

  @override
  Future<Map<String, dynamic>?> getSubscription() async {
    try {
      return (await _dio.get<Map<String, dynamic>>('/billing/subscription'))
          .data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> activate(Map<String, dynamic> body) async =>
      (await _dio.post<Map<String, dynamic>>(
        '/billing/subscription/activate',
        data: body,
      )).data!;

  @override
  Future<void> cancel() => _dio.post<void>('/billing/subscription/cancel');
}

@LazySingleton(as: BillingRepository)
class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remote, this._cache);

  static const plansKey = 'billing.plans';
  static const subscriptionKey = 'billing.subscription';

  final BillingRemoteDataSource _remote;
  final ResponseCache _cache;

  @override
  Stream<Result<List<Plan>>> watchPlans() => watchCachedApiCall(
    cache: _cache,
    key: plansKey,
    fetch: _remote.getPlans,
    parse: (json) => parseList(json as List<dynamic>, _plan),
  );

  @override
  Future<Result<SubscribeResponse>> subscribe(
    String planCode, {
    String? couponCode,
  }) => runApiCall(() async {
    final j = await _remote.subscribe({
      'planCode': planCode,
      'couponCode': ?couponCode,
    });
    return SubscribeResponse(
      subscriptionId: j.str('subscriptionId'),
      gatewayOrderId: j.str('gatewayOrderId'),
      amountPaise: j.integer('amountPaise'),
      currency: j.str('currency'),
      keyId: j.str('keyId'),
      planName: j.str('planName'),
      cycle: _cycle(j.str('billingCycle')),
      isStub: j.flag('isStub'),
    );
  });

  @override
  Future<Result<CouponValidation>> validateCoupon(
    String code,
    String planCode,
  ) => runApiCall(() async {
    final j = await _remote.validateCoupon({
      'code': code,
      'planCode': planCode,
    });
    return CouponValidation(
      isValid: j.flag('isValid'),
      originalAmountPaise: j.integer('originalAmountPaise'),
      discountPaise: j.integer('discountPaise'),
      finalAmountPaise: j.integer('finalAmountPaise'),
    );
  });

  @override
  Stream<Result<Subscription?>> watchCurrentSubscription() =>
      watchCachedApiCall(
        cache: _cache,
        key: subscriptionKey,
        // The cache stores JSON; an empty map stands for "no subscription".
        fetch: () async =>
            await _remote.getSubscription() ?? const <String, dynamic>{},
        parse: (json) {
          final j = Map<String, dynamic>.from(json as Map);
          return j.isEmpty ? null : _subscription(j);
        },
      );

  @override
  Future<Result<void>> cancelSubscription() => runApiCall(() async {
    await _remote.cancel();
    await _cache.invalidate(const [subscriptionKey]);
  });

  @override
  Future<Result<Subscription>> activateSubscription({
    required String orderId,
    required String paymentId,
    required String signature,
  }) => runApiCall(() async {
    final j = await _remote.activate({
      'razorpayOrderId': orderId,
      'razorpayPaymentId': paymentId,
      'razorpaySignature': signature,
    });
    await _cache.invalidate(const [subscriptionKey]);
    return _subscription(j);
  });

  static Plan _plan(Map<String, dynamic> j) => Plan(
    id: j.str('id'),
    code: j.str('code'),
    name: j.str('name'),
    // The API sends rupees as a decimal; paise from here on.
    pricePaise: (j.number('price') * 100).round(),
    currency: j.str('currency'),
    cycle: _cycle(j.str('billingPeriod')),
  );

  static Subscription _subscription(Map<String, dynamic> j) => Subscription(
    id: j.str('id'),
    planCode: j.str('planCode'),
    planName: j.str('planName'),
    status: switch (j.str('status')) {
      'Active' => SubscriptionStatus.active,
      'Cancelled' => SubscriptionStatus.cancelled,
      'Expired' => SubscriptionStatus.expired,
      _ => SubscriptionStatus.pendingPayment,
    },
    cycle: _cycle(j.str('billingCycle')),
    expiresAt: j.date('expiresAtUtc'),
  );

  static BillingCycle _cycle(String value) =>
      value == 'Yearly' ? BillingCycle.yearly : BillingCycle.monthly;
}
