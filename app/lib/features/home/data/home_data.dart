import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/home_entities.dart';
import '../domain/home_repository.dart';

/// `GET /home`:
/// ```json
/// { "userName": "…", "hasUnreadAlerts": true,
///   "categories": [{ "code": "agriculture", "name": "…", "highlights": ["…"] }],
///   "topOpportunity": { "commodityId": "…", "product": "…",
///     "categoryCode": "agriculture", "priceSource": "…",
///     "updatedAt": "ISO-8601", "price": 2150, "unit": "Quintal",
///     "change": -170, "percent": -7.3, "trend": [2400, 2150],
///     "bestMarketName": "…" } | null,
///   "watchlist": [{ "commodityId": "…", "marketId": "…", "name": "…",
///     "categoryCode": "…", "price": 2150, "unit": "q", "percent": -7.7 }] }
/// ```
abstract interface class HomeRemoteDataSource {
  Future<Map<String, dynamic>> getDashboard();
}

@LazySingleton(as: HomeRemoteDataSource)
class DioHomeRemoteDataSource implements HomeRemoteDataSource {
  DioHomeRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getDashboard() async =>
      (await _dio.get<Map<String, dynamic>>('/home')).data!;
}

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote, this._cache);

  final HomeRemoteDataSource _remote;
  final ResponseCache _cache;

  @override
  Future<Result<HomeDashboard>> getDashboard() => runCachedApiCall(
    cache: _cache,
    key: 'home',
    fetch: _remote.getDashboard,
    parse: (json) => HomeJson.dashboard(json as Map<String, dynamic>),
  );
}

abstract final class HomeJson {
  static HomeDashboard dashboard(Map<String, dynamic> j) {
    final top = j.objOrNull('topOpportunity');
    return HomeDashboard(
      userName: j.str('userName'),
      hasUnreadAlerts: j.flag('hasUnreadAlerts'),
      categories: j.list(
        'categories',
        (c) => HomeCategory(
          code: c.str('code'),
          name: c.str('name'),
          highlights: c.strings('highlights'),
        ),
      ),
      topOpportunity: top == null ? null : opportunity(top),
      watchlist: j.list(
        'watchlist',
        (w) => WatchlistPreview(
          commodityId: w.str('commodityId'),
          marketId: w.str('marketId'),
          name: w.str('name'),
          categoryCode: w.str('categoryCode'),
          price: w.number('price'),
          unit: w.str('unit'),
          percent: w.decimalOrNull('percent'),
        ),
      ),
    );
  }

  static TopOpportunity opportunity(Map<String, dynamic> o) => TopOpportunity(
    commodityId: o.str('commodityId'),
    product: o.str('product'),
    categoryCode: o.str('categoryCode'),
    priceSource: o.str('priceSource'),
    updatedAt: o.date('updatedAt'),
    price: o.number('price'),
    unit: o.str('unit'),
    change: o.numberOrNull('change'),
    percent: o.decimalOrNull('percent'),
    trend: o.numbers('trend'),
    bestMarketName: o.strOrNull('bestMarketName'),
  );
}
