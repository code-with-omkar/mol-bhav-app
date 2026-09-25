import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/watchlist.dart';

/// `GET /watchlist`:
/// ```json
/// { "updatedAt": "ISO-8601",
///   "categories": [{ "code": "agriculture", "name": "Agriculture" }],
///   "items": [{ "id": "…", "commodityId": "…", "marketId": "…",
///     "name": "Onion", "categoryCode": "agriculture", "variety": null,
///     "marketName": "Pune", "price": 2150, "unit": "q", "percent": -7.7,
///     "trend": [2330, 2150],
///     "alert": { "condition": "below", "value": 2000 } | null }] }
/// ```
abstract interface class WatchlistRemoteDataSource {
  Future<Map<String, dynamic>> getWatchlist();
}

@LazySingleton(as: WatchlistRemoteDataSource)
class DioWatchlistRemoteDataSource implements WatchlistRemoteDataSource {
  DioWatchlistRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getWatchlist() async =>
      (await _dio.get<Map<String, dynamic>>('/watchlist')).data!;
}

@LazySingleton(as: WatchlistRepository)
class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._remote, this._cache);

  final WatchlistRemoteDataSource _remote;
  final ResponseCache _cache;

  @override
  Future<Result<Watchlist>> getWatchlist() => runCachedApiCall(
    cache: _cache,
    key: 'watchlist',
    fetch: _remote.getWatchlist,
    parse: (json) => _watchlist(json as Map<String, dynamic>),
  );

  static Watchlist _watchlist(Map<String, dynamic> j) {
    return Watchlist(
      updatedAt: j['updatedAt'] == null ? null : j.date('updatedAt'),
      categories: j.list(
        'categories',
        (c) => WatchlistCategory(code: c.str('code'), name: c.str('name')),
      ),
      items: j.list('items', _item),
    );
  }

  static WatchlistItem _item(Map<String, dynamic> i) {
    final alert = i.objOrNull('alert');
    return WatchlistItem(
      id: i.str('id'),
      commodityId: i.str('commodityId'),
      marketId: i.str('marketId'),
      name: i.str('name'),
      categoryCode: i.str('categoryCode'),
      variety: i.strOrNull('variety'),
      marketName: i.strOrNull('marketName'),
      price: i.number('price'),
      unit: i.str('unit'),
      percent: i.decimalOrNull('percent'),
      trend: i.numbers('trend'),
      alertCondition: alert == null
          ? null
          : AlertCondition.values.byName(alert.str('condition')),
      alertValue: alert?.numberOrNull('value'),
    );
  }
}
