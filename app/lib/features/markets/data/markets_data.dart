import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/markets_entities.dart';
import '../domain/markets_repository.dart';

/// Remapped to available API endpoints:
///
/// - `GET /catalog/categories` + `GET /catalog/categories/{code}/products`
///   → `getCommodities()`
/// - `GET /pricing/latest?productId=` → `getComparison()`
/// - `GET /pricing/history?productId=&locationKind=Mandi&locationId=&fromDate=&toDate=`
///   → `getTrend()`
/// - `getOpportunity()` → not supported, returns empty result
abstract interface class MarketsRemoteDataSource {
  Future<List<dynamic>> getCategories();

  Future<List<dynamic>> getProductsForCategory(String categoryCode);

  Future<List<dynamic>> getLatestPrices(String productId);

  Future<List<dynamic>> getPriceHistory(
    String productId,
    String locationId,
    String fromDate,
    String toDate,
  );
}

@LazySingleton(as: MarketsRemoteDataSource)
class DioMarketsRemoteDataSource implements MarketsRemoteDataSource {
  DioMarketsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getCategories() async =>
      (await _dio.get<List<dynamic>>('/catalog/categories')).data ?? [];

  @override
  Future<List<dynamic>> getProductsForCategory(String categoryCode) async =>
      (await _dio.get<List<dynamic>>(
        '/catalog/categories/${Uri.encodeComponent(categoryCode)}/products',
        queryParameters: {'pageSize': 50},
      )).data ??
      [];

  @override
  Future<List<dynamic>> getLatestPrices(String productId) async =>
      (await _dio.get<List<dynamic>>(
        '/pricing/latest',
        queryParameters: {'productId': productId, 'pageSize': 50},
      )).data ??
      [];

  @override
  Future<List<dynamic>> getPriceHistory(
    String productId,
    String locationId,
    String fromDate,
    String toDate,
  ) async =>
      (await _dio.get<List<dynamic>>(
        '/pricing/history',
        queryParameters: {
          'productId': productId,
          'locationKind': 'Mandi',
          'locationId': locationId,
          'fromDate': fromDate,
          'toDate': toDate,
        },
      )).data ??
      [];
}

@LazySingleton(as: MarketsRepository)
class MarketsRepositoryImpl implements MarketsRepository {
  MarketsRepositoryImpl(this._remote, this._cache);

  final MarketsRemoteDataSource _remote;
  final ResponseCache _cache;

  @override
  Future<Result<List<Commodity>>> getCommodities() => runCachedApiCall(
    cache: _cache,
    key: 'markets.commodities.v2',
    ttl: referenceDataTtl,
    fetch: () async {
      final categories = await _remote.getCategories();
      final codes = [
        for (final cat in categories) (cat as Map<String, dynamic>).str('code'),
      ];
      final results = await Future.wait([
        for (final code in codes) _remote.getProductsForCategory(code),
      ]);
      // The product payload carries its sub-category, not its category, so the
      // only reliable code is the one the page was fetched under.
      return [
        for (final (i, page) in results.indexed)
          for (final product in page)
            {...product as Map<String, dynamic>, _categoryCode: codes[i]},
      ];
    },
    parse: (json) => parseList(
      json as List<dynamic>,
      (j) => Commodity(
        id: j.str('id'),
        name: j.str('name'),
        categoryCode: j.strOrNull(_categoryCode) ?? '',
      ),
    ),
  );

  /// Key the category code is folded into each cached product row under.
  static const _categoryCode = 'categoryCode';

  @override
  Stream<Result<MarketComparison>> watchComparison(
    String commodityId, {
    List<String>? marketIds,
  }) => watchCachedApiCall(
    cache: _cache,
    key: 'markets.comparison.$commodityId',
    fetch: () => _remote.getLatestPrices(commodityId),
    parse: (json) {
      final rows = (json as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final allIds = rows.map((r) => r['locationId'] as String).toList();
      final best = rows.isEmpty
          ? null
          : rows.reduce(
              (a, b) =>
                  (a['modalPrice'] as num) <= (b['modalPrice'] as num) ? a : b,
            );
      final source = rows.isNotEmpty ? rows.first.str('sourceName') : '';
      return MarketComparison(
        commodityId: commodityId,
        categoryCode: '',
        unit: rows.isNotEmpty ? rows.first.str('unitSymbol') : '',
        availableMarkets: [
          for (final r in rows)
            MarketRef(id: r.str('locationId'), name: r.str('locationName')),
        ],
        selectedMarketIds: marketIds ?? allIds,
        rows: [
          for (final r in rows)
            MarketPrice(
              marketId: r.str('locationId'),
              marketName: r.str('locationName'),
              price: r.number('modalPrice'),
              minPrice: r.numberOrNull('minPrice'),
              maxPrice: r.numberOrNull('maxPrice'),
              recordDate: r.date('recordDate'),
              source: r.str('sourceName'),
              change: null,
              arrivals: null,
            ),
        ],
        bestMarketId: best?.strOrNull('locationId'),
        homeMarketId: null,
        source: source,
        updatedAt: rows.isNotEmpty
            ? _parseDate(rows.first['recordDate'] as String)
            : DateTime.now(),
      );
    },
  );

  @override
  Future<Result<PriceTrend>> getTrend(
    String commodityId,
    String marketId,
    TrendRange range,
  ) => runCachedApiCall(
    cache: _cache,
    // v2: the payload now also carries the names, unit and source the screen
    // needs for its title and for a shared card.
    key: 'markets.trend.$commodityId.$marketId.${range.code}.v2',
    fetch: () async {
      final to = DateTime.now();
      final from = to.subtract(_rangeDuration(range));
      // The history endpoint returns dates and prices only, so the commodity
      // name comes from the cached catalog list and the market name, unit and
      // source from this product's latest-price rows. Both are cached reads.
      final (points, commodities, latest) = await (
        _remote.getPriceHistory(commodityId, marketId, _fmt(from), _fmt(to)),
        getCommodities(),
        _remote.getLatestPrices(commodityId),
      ).wait;
      final row = [for (final r in latest) r as Map<String, dynamic>]
          .where((r) => r.strOrNull('locationId') == marketId)
          .firstOrNull;
      return {
        _points: points,
        _commodityName:
            commodities
                .fold((_) => const <Commodity>[], (list) => list)
                .where((c) => c.id == commodityId)
                .firstOrNull
                ?.name ??
            '',
        _marketName: row?.strOrNull('locationName') ?? '',
        _unit: row?.strOrNull('unitSymbol') ?? '',
        _source: row?.strOrNull('sourceName') ?? '',
      };
    },
    parse: (json) {
      final payload = json as Map<String, dynamic>;
      final points = [
        for (final p in payload[_points] as List<dynamic>)
          p as Map<String, dynamic>,
      ];
      final prices = points.map((p) => p.number('modalPrice')).toList();
      return PriceTrend(
        commodityName: payload.str(_commodityName),
        marketName: payload.str(_marketName),
        unit: payload.str(_unit),
        source: payload.str(_source),
        points: [
          for (final p in points)
            TrendSample(
              date: _parseDate(p['recordDate'] as String),
              value: p.number('modalPrice'),
              min: p.numberOrNull('minPrice'),
              max: p.numberOrNull('maxPrice'),
            ),
        ],
        min: prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b),
        modal: prices.isEmpty ? 0 : prices[prices.length ~/ 2],
        max: prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b),
        related: const [],
      );
    },
  );

  // Keys of the composed, cached trend payload.
  static const _points = 'points';
  static const _commodityName = 'commodityName';
  static const _marketName = 'marketName';
  static const _unit = 'unit';
  static const _source = 'source';

  @override
  Future<Result<BuyingOpportunity>> getOpportunity(String id) async =>
      Err(UnexpectedFailure());

  static Duration _rangeDuration(TrendRange range) => switch (range) {
    TrendRange.week => const Duration(days: 7),
    TrendRange.month => const Duration(days: 30),
    TrendRange.quarter => const Duration(days: 90),
    TrendRange.year => const Duration(days: 365),
  };

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String s) => DateTime.parse(s);
}
