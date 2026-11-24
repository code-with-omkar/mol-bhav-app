import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_billing.dart';

/// `/admin/billing/plans` and `/admin/coupons`.
@LazySingleton(as: AdminBillingRepository)
class AdminBillingRepositoryImpl implements AdminBillingRepository {
  AdminBillingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminPlan>>> getPlans() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>('/admin/billing/plans')).data;
    return [
      for (final j in (rows ?? const []).cast<Map<String, dynamic>>())
        parsePlan(j),
    ];
  });

  @override
  Future<Result<void>> createPlan(PlanDraft draft) => runApiCall(
    () => _dio.post<void>(
      '/admin/billing/plans',
      data: {
        'code': draft.code.trim(),
        'name': draft.name.trim(),
        'price': draft.priceValue,
        'currency': 'INR',
        'billingPeriod': draft.period.wire,
      },
    ),
  );

  @override
  Future<Result<void>> updatePlan(String id, PlanDraft draft) => runApiCall(
    () => _dio.put<void>(
      '/admin/billing/plans/${Uri.encodeComponent(id)}',
      data: {
        'name': draft.name.trim(),
        'price': draft.priceValue,
        'isActive': draft.isActive,
      },
    ),
  );

  @override
  Future<Result<List<AdminCoupon>>> getCoupons({
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/coupons',
      queryParameters: {'page': page, 'pageSize': pageSize},
    )).data;
    return [
      for (final j in (rows ?? const []).cast<Map<String, dynamic>>())
        parseCoupon(j),
    ];
  });

  @override
  Future<Result<void>> createCoupon(CouponDraft draft) => runApiCall(
    () => _dio.post<void>(
      '/admin/coupons',
      data: {
        'code': draft.code.trim(),
        'discountType': draft.kind.wire,
        'discountValue': draft.discountValue,
        'maxUses': draft.maxUsesValue,
        'validFrom': draft.validFrom?.toIso8601String(),
        'validTo': draft.validTo?.toIso8601String(),
        'applicablePlanCode': draft.planCode,
        'minAmountPaise': draft.minAmountPaise ?? 0,
      },
    ),
  );

  @override
  Future<Result<void>> updateCoupon(String id, CouponEdit edit) => runApiCall(
    () => _dio.put<void>(
      '/admin/coupons/${Uri.encodeComponent(id)}',
      data: {
        'isActive': edit.isActive,
        'validTo': edit.validTo?.toIso8601String(),
        'maxUses': edit.maxUsesValue,
      },
    ),
  );

  static AdminPlan parsePlan(Map<String, dynamic> j) => AdminPlan(
    id: j.str('id'),
    code: j.str('code'),
    name: j.str('name'),
    price: j.number('price').toDouble(),
    currency: j.str('currency'),
    period: PlanPeriod.fromWire(j.str('billingPeriod')),
    isActive: j.flag('isActive'),
  );

  static AdminCoupon parseCoupon(Map<String, dynamic> j) => AdminCoupon(
    id: j.str('id'),
    code: j.str('code'),
    kind: CouponKind.fromWire(j.str('discountType')),
    value: j.integer('discountValue'),
    maxUses: j['maxUses'] is int ? j['maxUses'] as int : null,
    usesCount: j.integer('usesCount'),
    validFrom: j.date('validFrom'),
    validTo: j.dateOrNull('validTo'),
    planCode: j.strOrNull('applicablePlanCode'),
    minAmountPaise: j.integer('minAmountPaise'),
    isActive: j.flag('isActive'),
  );
}
