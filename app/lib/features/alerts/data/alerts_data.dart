import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/alerts.dart';

/// Alert endpoints:
///
/// - `GET /alerts?filter=all|signals|opportunities` →
///   `[{ id, kind: signal|opportunity|spike, isUnread, title, details: [],
///   channel: whatsapp|push|null, createdAt, opportunityId }]`
/// - `GET /alerts/options` → `{ products: [{ id, name, categoryCode, unit }],
///   markets: [{ id, name }], whatsappNumber, whatsappLanguage }`
/// - `GET /markets/price?commodityId=&marketId=` → `{ marketName, price, unit }`
/// - `POST /alerts` with `{ commodityId, marketId,
///   condition: below|above|percent, value, channels: { push, whatsapp } }`
abstract interface class AlertsRemoteDataSource {
  Future<List<dynamic>> getAlerts(String filter);

  Future<Map<String, dynamic>> getOptions();

  Future<Map<String, dynamic>> getCurrentPrice(
    String commodityId,
    String marketId,
  );

  Future<void> create(Map<String, dynamic> body);
}

@LazySingleton(as: AlertsRemoteDataSource)
class DioAlertsRemoteDataSource implements AlertsRemoteDataSource {
  DioAlertsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getAlerts(String filter) async =>
      (await _dio.get<List<dynamic>>(
        '/alerts',
        queryParameters: {'filter': filter},
      )).data!;

  @override
  Future<Map<String, dynamic>> getOptions() async =>
      (await _dio.get<Map<String, dynamic>>('/alerts/options')).data!;

  @override
  Future<Map<String, dynamic>> getCurrentPrice(
    String commodityId,
    String marketId,
  ) async => (await _dio.get<Map<String, dynamic>>(
    '/markets/price',
    queryParameters: {'commodityId': commodityId, 'marketId': marketId},
  )).data!;

  @override
  Future<void> create(Map<String, dynamic> body) =>
      _dio.post<void>('/alerts', data: body);
}

@LazySingleton(as: AlertsRepository)
class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl(this._remote);

  final AlertsRemoteDataSource _remote;

  @override
  Future<Result<List<AlertItem>>> getAlerts(AlertFilter filter) => runApiCall(
    () async => parseList(
      await _remote.getAlerts(filter.name),
      (a) => AlertItem(
        id: a.str('id'),
        kind: AlertKind.values.byName(a.str('kind')),
        isUnread: a.flag('isUnread'),
        title: a.str('title'),
        details: a.strings('details'),
        createdAt: a.date('createdAt'),
        channel: switch (a.strOrNull('channel')) {
          'whatsapp' => AlertChannel.whatsapp,
          'push' => AlertChannel.push,
          _ => null,
        },
        opportunityId: a.strOrNull('opportunityId'),
      ),
    ),
  );

  @override
  Future<Result<AlertOptions>> getOptions() => runApiCall(() async {
    final j = await _remote.getOptions();
    return AlertOptions(
      products: j.list(
        'products',
        (p) => AlertProduct(
          id: p.str('id'),
          name: p.str('name'),
          categoryCode: p.str('categoryCode'),
          unit: p.str('unit'),
        ),
      ),
      markets: j.list(
        'markets',
        (m) => AlertMarket(id: m.str('id'), name: m.str('name')),
      ),
      whatsappNumber: j.strOrNull('whatsappNumber'),
      whatsappLanguage: j.strOrNull('whatsappLanguage'),
    );
  });

  @override
  Future<Result<CurrentPrice>> getCurrentPrice(
    String commodityId,
    String marketId,
  ) => runApiCall(() async {
    final j = await _remote.getCurrentPrice(commodityId, marketId);
    return CurrentPrice(
      marketName: j.str('marketName'),
      price: j.number('price'),
      unit: j.str('unit'),
    );
  });

  @override
  Future<Result<void>> create(NewAlert alert) => runApiCall(
    () => _remote.create({
      'commodityId': alert.commodityId,
      'marketId': alert.marketId,
      'condition': alert.condition.name,
      'value': alert.value,
      'channels': {'push': alert.push, 'whatsapp': alert.whatsapp},
    }),
  );
}
