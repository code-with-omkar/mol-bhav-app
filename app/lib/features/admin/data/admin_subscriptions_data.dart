import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_subscriptions.dart';

/// `GET /admin/billing/subscriptions` and `POST …/{id}/expire`.
@LazySingleton(as: AdminSubscriptionsRepository)
class AdminSubscriptionsRepositoryImpl implements AdminSubscriptionsRepository {
  AdminSubscriptionsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminSubscription>>> getSubscriptions({
    SubscriptionState? status,
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/billing/subscriptions',
      queryParameters: {
        'status': ?status?.wire,
        'page': page,
        'pageSize': pageSize,
      },
    )).data;
    return [
      for (final j in (rows ?? const []).cast<Map<String, dynamic>>()) parse(j),
    ];
  });

  @override
  Future<Result<void>> expire(String subscriptionId) => runApiCall(
    () => _dio.post<void>(
      '/admin/billing/subscriptions/${Uri.encodeComponent(subscriptionId)}/expire',
    ),
  );

  static AdminSubscription parse(Map<String, dynamic> j) {
    String? text(String key) {
      final v = j[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return AdminSubscription(
      id: j.str('id'),
      userId: j.str('userId'),
      planCode: j.str('planCode'),
      status: SubscriptionState.fromWire(j.str('status')),
      startedAt: j.date('startedAtUtc'),
      expiresAt: j.date('expiresAtUtc'),
      isAutoRenew: j.flag('isAutoRenew'),
      cancelledAt: j.dateOrNull('cancelledAtUtc'),
      userPhone: text('userPhoneNumberMasked'),
      userName: text('userName'),
    );
  }
}
