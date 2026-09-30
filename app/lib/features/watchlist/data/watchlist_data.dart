import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/watchlist.dart';

/// `GET /watchlist`:
/// After envelope unwrap → `[WatchlistItemResponse]`:
/// ```json
/// [{ "id": "…",
///    "product": { "id": "…", "code": "onion", "name": "Onion",
///                 "defaultUnit": { "symbol": "q" } },
///    "variantId": null, "variantName": null,
///    "addedAtUtc": "…",
///    "latestPrice": 2150.0, "priceUnitSymbol": "q", "percentChange": -7.7 }]
/// ```
/// `POST /watchlist` `{ productId, variantId? }` → 201, 409 when already watched.
/// `DELETE /watchlist/{id}` → 204.
abstract interface class WatchlistRemoteDataSource {
  Future<List<dynamic>> getWatchlist();

  Future<void> add(String productId, String? variantId);

  Future<void> remove(String itemId);
}

@LazySingleton(as: WatchlistRemoteDataSource)
class DioWatchlistRemoteDataSource implements WatchlistRemoteDataSource {
  DioWatchlistRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getWatchlist() async =>
      (await _dio.get<List<dynamic>>('/watchlist')).data!;

  @override
  Future<void> add(String productId, String? variantId) => _dio.post<void>(
    '/watchlist',
    data: {'productId': productId, 'variantId': variantId},
  );

  @override
  Future<void> remove(String itemId) =>
      _dio.delete<void>('/watchlist/${Uri.encodeComponent(itemId)}');
}

@LazySingleton(as: WatchlistRepository)
class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(this._remote, this._cache);

  final WatchlistRemoteDataSource _remote;
  final ResponseCache _cache;

  static const _key = 'watchlist';

  @override
  Stream<Result<Watchlist>> watchWatchlist() => watchCachedApiCall(
    cache: _cache,
    key: _key,
    fetch: _remote.getWatchlist,
    parse: (json) => _watchlist(json as List<dynamic>),
  );

  @override
  Future<Result<void>> add(String productId, {String? variantId}) async {
    final result = await runApiCall(
      () => _remote.add(productId, variantId),
      mapError: (e) =>
          e.response?.statusCode == 409 ? const AlreadyWatchedFailure() : null,
    );
    await _cache.invalidate(const [_key]);
    return result;
  }

  @override
  Future<Result<void>> remove(String itemId) async {
    final result = await runApiCall(() => _remote.remove(itemId));
    await _cache.invalidate(const [_key]);
    return result;
  }

  static Watchlist _watchlist(List<dynamic> items) {
    final parsed = items.map((e) => _item(e as Map<String, dynamic>)).toList();
    return Watchlist(updatedAt: null, categories: const [], items: parsed);
  }

  static WatchlistItem _item(Map<String, dynamic> i) {
    final product = i.obj('product');
    final unit = product.obj('defaultUnit');
    return WatchlistItem(
      id: i.str('id'),
      commodityId: product.str('id'),
      variantId: i.strOrNull('variantId'),
      marketId: '',
      name: product.str('name'),
      categoryCode: '',
      price: i.numberOrNull('latestPrice') ?? 0,
      unit: i.strOrNull('priceUnitSymbol') ?? unit.str('symbol'),
      percent: i.decimalOrNull('percentChange'),
      trend: const [],
      variety: i.strOrNull('variantName'),
      marketName: null,
      alertCondition: null,
      alertValue: null,
    );
  }
}
