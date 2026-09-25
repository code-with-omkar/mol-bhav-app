import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/markets_entities.dart';
import '../domain/markets_repository.dart';

/// Market data endpoints (names localised by `Accept-Language`):
///
/// - `GET /markets/commodities` → `[{ id, name, categoryCode }]`
/// - `GET /markets/comparison?commodityId=&marketIds=a,b` →
///   `{ commodityId, categoryCode, unit, availableMarkets: [{ id, name }],
///   selectedMarketIds: [], homeMarketId, bestMarketId, source, updatedAt,
///   rows: [{ marketId, marketName, price, change, arrivals }] }`
/// - `GET /markets/trends?commodityId=&marketId=&range=30D` →
///   `{ commodityName, marketName, unit, min, modal, max,
///   points: [{ date, value }],
///   related: [{ marketId, marketName, price, unit, percent }] }`
/// - `GET /opportunities/{id}` → `{ id, commodityName, categoryCode,
///   quantity, quantityUnit, deliverTo, priceUnit, bestMarketId,
///   referenceMarketId, potentialDifference, source, updatedAt,
///   markets: [{ marketId, marketName, price }] }`
abstract interface class MarketsRemoteDataSource {
  Future<List<dynamic>> getCommodities();

  Future<Map<String, dynamic>> getComparison(
    String commodityId,
    List<String>? marketIds,
  );

  Future<Map<String, dynamic>> getTrend(
    String commodityId,
    String marketId,
    String range,
  );

  Future<Map<String, dynamic>> getOpportunity(String id);
}

@LazySingleton(as: MarketsRemoteDataSource)
class DioMarketsRemoteDataSource implements MarketsRemoteDataSource {
  DioMarketsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getCommodities() async =>
      (await _dio.get<List<dynamic>>('/markets/commodities')).data!;

  @override
  Future<Map<String, dynamic>> getComparison(
    String commodityId,
    List<String>? marketIds,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/markets/comparison',
      queryParameters: {
        'commodityId': commodityId,
        if (marketIds != null) 'marketIds': marketIds.join(','),
      },
    );
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> getTrend(
    String commodityId,
    String marketId,
    String range,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/markets/trends',
      queryParameters: {
        'commodityId': commodityId,
        'marketId': marketId,
        'range': range,
      },
    );
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> getOpportunity(String id) async =>
      (await _dio.get<Map<String, dynamic>>(
        '/opportunities/${Uri.encodeComponent(id)}',
      )).data!;
}

@LazySingleton(as: MarketsRepository)
class MarketsRepositoryImpl implements MarketsRepository {
  MarketsRepositoryImpl(this._remote, this._cache);

  final MarketsRemoteDataSource _remote;

  /// Prices stay readable offline; the opportunity detail is not cached.
  final ResponseCache _cache;

  @override
  Future<Result<List<Commodity>>> getCommodities() => runCachedApiCall(
    cache: _cache,
    key: 'markets.commodities',
    fetch: _remote.getCommodities,
    parse: (json) => parseList(
      json as List<dynamic>,
      (j) => Commodity(
        id: j.str('id'),
        name: j.str('name'),
        categoryCode: j.str('categoryCode'),
      ),
    ),
  );

  @override
  Future<Result<MarketComparison>> getComparison(
    String commodityId, {
    List<String>? marketIds,
  }) => runCachedApiCall(
    cache: _cache,
    key:
        'markets.comparison.$commodityId.'
        '${marketIds == null ? 'default' : (marketIds.toList()..sort()).join(',')}',
    fetch: () => _remote.getComparison(commodityId, marketIds),
    parse: (json) => _comparison(json as Map<String, dynamic>),
  );

  @override
  Future<Result<PriceTrend>> getTrend(
    String commodityId,
    String marketId,
    TrendRange range,
  ) => runCachedApiCall(
    cache: _cache,
    key: 'markets.trend.$commodityId.$marketId.${range.code}',
    fetch: () => _remote.getTrend(commodityId, marketId, range.code),
    parse: (json) => _trend(json as Map<String, dynamic>),
  );

  @override
  Future<Result<BuyingOpportunity>> getOpportunity(String id) =>
      runApiCall(() async => _opportunity(await _remote.getOpportunity(id)));

  static MarketComparison _comparison(Map<String, dynamic> j) =>
      MarketComparison(
        commodityId: j.str('commodityId'),
        categoryCode: j.str('categoryCode'),
        unit: j.str('unit'),
        availableMarkets: j.list(
          'availableMarkets',
          (m) => MarketRef(id: m.str('id'), name: m.str('name')),
        ),
        selectedMarketIds: j.strings('selectedMarketIds'),
        rows: j.list(
          'rows',
          (r) => MarketPrice(
            marketId: r.str('marketId'),
            marketName: r.str('marketName'),
            price: r.number('price'),
            change: r.numberOrNull('change'),
            arrivals: r.strOrNull('arrivals'),
          ),
        ),
        bestMarketId: j.strOrNull('bestMarketId'),
        homeMarketId: j.strOrNull('homeMarketId'),
        source: j.str('source'),
        updatedAt: j.date('updatedAt'),
      );

  static PriceTrend _trend(Map<String, dynamic> j) => PriceTrend(
    commodityName: j.str('commodityName'),
    marketName: j.str('marketName'),
    unit: j.str('unit'),
    min: j.number('min'),
    modal: j.number('modal'),
    max: j.number('max'),
    points: j.list(
      'points',
      (p) => TrendSample(date: p.date('date'), value: p.number('value')),
    ),
    related: j.list(
      'related',
      (r) => RelatedMarketPrice(
        marketId: r.str('marketId'),
        marketName: r.str('marketName'),
        price: r.number('price'),
        unit: r.str('unit'),
        percent: r.decimalOrNull('percent'),
      ),
    ),
  );

  static BuyingOpportunity _opportunity(Map<String, dynamic> j) =>
      BuyingOpportunity(
        id: j.str('id'),
        commodityName: j.str('commodityName'),
        categoryCode: j.str('categoryCode'),
        quantity: j.number('quantity'),
        quantityUnit: j.str('quantityUnit'),
        deliverTo: j.str('deliverTo'),
        priceUnit: j.str('priceUnit'),
        markets: j.list(
          'markets',
          (m) => MarketRefPrice(
            marketId: m.str('marketId'),
            marketName: m.str('marketName'),
            price: m.number('price'),
          ),
        ),
        bestMarketId: j.str('bestMarketId'),
        referenceMarketId: j.str('referenceMarketId'),
        potentialDifference: j.number('potentialDifference'),
        source: j.str('source'),
        updatedAt: j.date('updatedAt'),
      );
}
