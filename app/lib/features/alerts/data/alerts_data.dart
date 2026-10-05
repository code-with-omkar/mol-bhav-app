import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/alerts.dart';

/// Alert endpoints:
///
/// - `GET /alerts?page=&pageSize=` → paged `[AlertResponse]`
/// - `GET /alert-rules` → `[AlertRuleResponse]`
/// - `POST /alert-rules` with `CreateAlertRuleRequest`
/// - `POST /alerts/{alertId}/read`
///
/// The Create Alert form's reference data comes from elsewhere:
/// - products from the cached `CatalogRepository`, for the user's categories
/// - markets from `GET /market/mandis`
abstract interface class AlertsRemoteDataSource {
  Future<List<dynamic>> getAlerts(int page, int pageSize);

  Future<List<dynamic>> getMandis();

  Future<List<dynamic>> getLatestPrices(String productId);

  Future<void> create(Map<String, dynamic> body);

  Future<List<dynamic>> getAlertRules();

  Future<void> updateAlertRule(String id, Map<String, dynamic> body);

  Future<void> deleteAlertRule(String id);
}

@LazySingleton(as: AlertsRemoteDataSource)
class DioAlertsRemoteDataSource implements AlertsRemoteDataSource {
  DioAlertsRemoteDataSource(this._dio);

  final Dio _dio;

  /// The API caps a page at 100, so the mandi master is walked page by page.
  static const _pageSize = 100;
  static const _maxMandiPages = 10;

  @override
  Future<List<dynamic>> getAlerts(int page, int pageSize) async =>
      (await _dio.get<List<dynamic>>(
        '/alerts',
        queryParameters: {'page': page, 'pageSize': pageSize},
      )).data ??
      [];

  @override
  Future<List<dynamic>> getMandis() async {
    final mandis = <dynamic>[];
    for (var page = 1; page <= _maxMandiPages; page++) {
      final rows =
          (await _dio.get<List<dynamic>>(
            '/market/mandis',
            queryParameters: {'page': page, 'pageSize': _pageSize},
          )).data ??
          const [];
      mandis.addAll(rows);
      if (rows.length < _pageSize) break;
    }
    return mandis;
  }

  @override
  Future<List<dynamic>> getLatestPrices(String productId) async =>
      (await _dio.get<List<dynamic>>(
        '/pricing/latest',
        queryParameters: {'productId': productId, 'pageSize': _pageSize},
      )).data ??
      [];

  @override
  Future<void> create(Map<String, dynamic> body) =>
      _dio.post<void>('/alert-rules', data: body);

  @override
  Future<List<dynamic>> getAlertRules() async =>
      (await _dio.get<List<dynamic>>('/alert-rules')).data ?? [];

  @override
  Future<void> updateAlertRule(String id, Map<String, dynamic> body) =>
      _dio.put<void>('/alert-rules/$id', data: body);

  @override
  Future<void> deleteAlertRule(String id) =>
      _dio.delete<void>('/alert-rules/$id');
}

@LazySingleton(as: AlertsRepository)
class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl(this._remote, this._catalog, this._cache);

  final AlertsRemoteDataSource _remote;
  final CatalogRepository _catalog;
  final ResponseCache _cache;

  static const alertsKey = 'alerts.list';
  static const rulesKey = 'alerts.rules';
  static const mandisKey = 'alerts.mandis.v1';

  /// One cached page for every filter: the filters are applied on the device.
  @override
  Stream<Result<List<AlertItem>>> watchAlerts(AlertFilter filter) =>
      watchCachedApiCall(
        cache: _cache,
        key: alertsKey,
        fetch: () => _remote.getAlerts(1, 50),
        parse: (json) {
          final items = parseList(json as List<dynamic>, _alertItem);
          return switch (filter) {
            AlertFilter.all => items,
            AlertFilter.signals => [
              for (final a in items)
                if (a.kind != AlertKind.opportunity) a,
            ],
            AlertFilter.opportunities => [
              for (final a in items)
                if (a.kind == AlertKind.opportunity) a,
            ],
          };
        },
      );

  /// Every catalog product tagged with the category it was fetched under, plus
  /// the mandi master. `CreateAlertCubit` narrows the products to the user's
  /// own categories; the catalog reads are cached reference data.
  @override
  Future<Result<AlertOptions>> getOptions() async {
    final categories = await _catalog.getCategories();
    return switch (categories) {
      Err(:final failure) => Err(failure),
      Ok(value: final list) => await _options(list),
    };
  }

  Future<Result<AlertOptions>> _options(
    List<CatalogCategory> categories,
  ) async {
    final (products, mandis) = await (
      Future.wait([
        for (final category in categories) _catalog.getProducts(category.code),
      ]),
      // Mandi master changes rarely: a day-old copy opens the form at once.
      runCachedApiCall<List<AlertMarket>>(
        cache: _cache,
        key: mandisKey,
        ttl: referenceDataTtl,
        fetch: _remote.getMandis,
        parse: (json) => [
          for (final m in json as List<dynamic>)
            AlertMarket(
              id: (m as Map<String, dynamic>).str('id'),
              name: m.str('name'),
              stateName: m.strOrNull('stateName') ?? '',
            ),
        ],
      ),
    ).wait;
    return switch (mandis) {
      Err(:final failure) => Err(failure),
      Ok(value: final markets) => Ok(
        AlertOptions(
          products: [
            for (final (i, page) in products.indexed)
              for (final product in page.fold(
                (_) => const <CatalogProduct>[],
                (p) => p,
              ))
                AlertProduct(
                  id: product.id,
                  name: product.name,
                  categoryCode: categories[i].code,
                  unit: product.defaultUnit.symbol,
                ),
          ],
          markets: markets,
        ),
      ),
    };
  }

  @override
  Future<Result<CurrentPrice>> getCurrentPrice(
    String commodityId,
    String marketId,
  ) => runApiCall(() async {
    final rows = [
      for (final r in await _remote.getLatestPrices(commodityId))
        r as Map<String, dynamic>,
    ];
    // `/pricing/latest` returns one row per location; the hint is about the
    // mandi the rule will watch, so anything else would mislead.
    final row = rows
        .where((r) => r.strOrNull('locationId') == marketId)
        .firstOrNull;
    if (row == null) {
      return const CurrentPrice(marketName: '—', price: 0, unit: '—');
    }
    return CurrentPrice(
      marketName: row.str('locationName'),
      price: row.number('modalPrice'),
      unit: row.str('unitSymbol'),
    );
  });

  @override
  Future<Result<void>> create(NewAlert alert) => _thenDropRules(
    () => _remote.create({
      'productId': alert.commodityId,
      'locationKind': 'Mandi',
      'mandiId': alert.marketId,
      // Rupee conditions are price-level rules; "changes by %" fires on a move
      // either way (it used to be sent as PriceDrop, so rises never alerted).
      'thresholdType': switch (alert.condition) {
        PriceCondition.below => 'PriceBelow',
        PriceCondition.above => 'PriceAbove',
        PriceCondition.percent => 'PriceChange',
      },
      if (alert.condition == PriceCondition.percent)
        'thresholdPercent': alert.value
      else
        'thresholdPrice': alert.value,
    }),
  );

  @override
  Stream<Result<List<AlertRule>>> watchAlertRules() => watchCachedApiCall(
    cache: _cache,
    key: rulesKey,
    fetch: _remote.getAlertRules,
    parse: (json) => parseList(json as List<dynamic>, _alertRule),
  );

  @override
  Future<Result<void>> updateAlertRule(String id, UpdateAlertRuleRequest req) =>
      _thenDropRules(
        () => _remote.updateAlertRule(id, {
          'thresholdType': _thresholdTypeName(req.thresholdType),
          if (req.thresholdPercent != null)
            'thresholdPercent': req.thresholdPercent,
          if (req.thresholdPrice != null) 'thresholdPrice': req.thresholdPrice,
          'isActive': req.isActive,
        }),
      );

  @override
  Future<Result<void>> deleteAlertRule(String id) =>
      _thenDropRules(() => _remote.deleteAlertRule(id));

  /// Runs a rule change, then drops the saved rules so screens reload live.
  Future<Result<void>> _thenDropRules(Future<void> Function() change) async {
    final result = await runApiCall(change);
    if (result is Ok<void>) await _cache.invalidate(const [rulesKey]);
    return result;
  }

  static String _thresholdTypeName(AlertThresholdType type) => switch (type) {
    AlertThresholdType.priceDrop => 'PriceDrop',
    AlertThresholdType.priceSpike => 'PriceSpike',
    AlertThresholdType.priceBelow => 'PriceBelow',
    AlertThresholdType.priceAbove => 'PriceAbove',
    AlertThresholdType.priceChange => 'PriceChange',
  };

  static AlertThresholdType _thresholdTypeFrom(String s) => switch (s) {
    'PriceSpike' => AlertThresholdType.priceSpike,
    'PriceBelow' => AlertThresholdType.priceBelow,
    'PriceAbove' => AlertThresholdType.priceAbove,
    'PriceChange' => AlertThresholdType.priceChange,
    _ => AlertThresholdType.priceDrop,
  };

  static AlertRule _alertRule(Map<String, dynamic> r) {
    final product = r.obj('product');
    final location = r.strOrNull('locationName');
    return AlertRule(
      id: r.str('id'),
      productName: product.str('name'),
      variantName: product.strOrNull('variantName'),
      locationName: location != null && location.isNotEmpty ? location : null,
      thresholdType: _thresholdTypeFrom(r.strOrNull('thresholdType') ?? ''),
      thresholdPercent: r.numberOrNull('thresholdPercent'),
      thresholdPrice: r.numberOrNull('thresholdPrice'),
      unit: r.strOrNull('unit') ?? '',
      isActive: r.flag('isActive'),
      createdAtUtc: r.date('createdAtUtc'),
    );
  }

  static AlertItem _alertItem(Map<String, dynamic> a) {
    final product = a.obj('product');
    final thresholdType = a.strOrNull('thresholdType') ?? '';
    final location = a.strOrNull('locationName');
    final percentChange = a.numberOrNull('percentChange') ?? 0;
    return AlertItem(
      id: a.str('id'),
      // An either-way rule takes its kind from the move itself.
      kind:
          thresholdType == 'PriceSpike' ||
              thresholdType == 'PriceAbove' ||
              (thresholdType == 'PriceChange' && percentChange > 0)
          ? AlertKind.spike
          : AlertKind.signal,
      isUnread: !(a.flag('isRead')),
      productName: product.str('name'),
      percentChange: percentChange,
      previousPrice: a.numberOrNull('previousPrice') ?? 0,
      newPrice: a.numberOrNull('newPrice') ?? 0,
      locationName: location != null && location.isNotEmpty ? location : null,
      createdAt: a.date('triggeredAtUtc'),
      channel: null,
      opportunityId: null,
    );
  }
}
