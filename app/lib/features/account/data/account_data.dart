import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../../../core/session/session_manager.dart';
import '../domain/account.dart';

/// Account endpoints:
///
/// - `GET /me` → `{ name, businessTypeName, districtName, stateName,
///   categoryNames: [], isPro, proMonthlyPrice, pushEnabled,
///   whatsappEnabled }`
/// - `PUT /me/notifications` with `{ push, whatsapp }`
/// - `GET /subscription/plans` → `[{ id, name, price,
///   period: month|year|null, features: [], isFeatured, isCurrent }]`
abstract interface class AccountRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();

  Future<void> updateNotifications(Map<String, dynamic> body);

  Future<List<dynamic>> getPlans();
}

@LazySingleton(as: AccountRemoteDataSource)
class DioAccountRemoteDataSource implements AccountRemoteDataSource {
  DioAccountRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getProfile() async =>
      (await _dio.get<Map<String, dynamic>>('/me')).data!;

  @override
  Future<void> updateNotifications(Map<String, dynamic> body) =>
      _dio.put<void>('/me/notifications', data: body);

  @override
  Future<List<dynamic>> getPlans() async =>
      (await _dio.get<List<dynamic>>('/subscription/plans')).data!;
}

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote, this._session);

  final AccountRemoteDataSource _remote;
  final SessionManager _session;

  @override
  Future<Result<AccountProfile>> getProfile() => runApiCall(() async {
    final j = await _remote.getProfile();
    return AccountProfile(
      name: j.str('name'),
      businessTypeName: j.str('businessTypeName'),
      districtName: j.str('districtName'),
      stateName: j.str('stateName'),
      categoryNames: j.strings('categoryNames'),
      isPro: j.flag('isPro'),
      proMonthlyPrice: j.numberOrNull('proMonthlyPrice'),
      pushEnabled: j.flag('pushEnabled'),
      whatsappEnabled: j.flag('whatsappEnabled'),
    );
  });

  @override
  Future<Result<void>> updateNotifications({
    required bool push,
    required bool whatsapp,
  }) => runApiCall(
    () => _remote.updateNotifications({'push': push, 'whatsapp': whatsapp}),
  );

  @override
  Future<Result<List<SubscriptionPlan>>> getPlans() => runApiCall(
    () async => parseList(
      await _remote.getPlans(),
      (p) => SubscriptionPlan(
        id: p.str('id'),
        name: p.str('name'),
        price: p.number('price'),
        period: switch (p.strOrNull('period')) {
          'month' => BillingPeriod.month,
          'year' => BillingPeriod.year,
          _ => null,
        },
        features: p.strings('features'),
        isFeatured: p.flag('isFeatured'),
        isCurrent: p.flag('isCurrent'),
      ),
    ),
  );

  @override
  Future<void> signOut() => _session.signOut();
}
