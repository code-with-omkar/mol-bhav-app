import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

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
  AlertsRepositoryImpl(this._remote, this._catalog);

  final AlertsRemoteDataSource _remote;
  final CatalogRepository _catalog;

  @override
  Future<Result<List<AlertItem>>> getAlerts(AlertFilter filter) =>
      runApiCall(() async {
        final items = parseList(await _remote.getAlerts(1, 50), _alertItem);
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
      });

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

  Future<Result<AlertOptions>> _options(List<CatalogCategory> categories) =>
      runApiCall(() async {
        final (products, mandis) = await (
          Future.wait([
            for (final category in categories)
              _catalog.getProducts(category.code),
          ]),
          _remote.getMandis(),
        ).wait;
        return AlertOptions(
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
          markets: [
            for (final m in mandis)
              AlertMarket(
                id: (m as Map<String, dynamic>).str('id'),
                name: m.str('name'),
                stateName: m.strOrNull('stateName') ?? '',
              ),
          ],
        );
      });

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
  Future<Result<void>> create(NewAlert alert) => runApiCall(
    () => _remote.create({
      'productId': alert.commodityId,
      'locationKind': 'Mandi',
      'mandiId': alert.marketId,
      // Rupee conditions are price-level rules; only "changes by %" is a percent one.
      'thresholdType': switch (alert.condition) {
        PriceCondition.below => 'PriceBelow',
        PriceCondition.above => 'PriceAbove',
        PriceCondition.percent => 'PriceDrop',
      },
      if (alert.condition == PriceCondition.percent)
        'thresholdPercent': alert.value
      else
        'thresholdPrice': alert.value,
    }),
  );

  @override
  Future<Result<List<AlertRule>>> getAlertRules() => runApiCall(
    () async => parseList(await _remote.getAlertRules(), _alertRule),
  );

  @override
  Future<Result<void>> updateAlertRule(String id, UpdateAlertRuleRequest req) =>
      runApiCall(
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
      runApiCall(() => _remote.deleteAlertRule(id));

  static String _thresholdTypeName(AlertThresholdType type) => switch (type) {
    AlertThresholdType.priceDrop => 'PriceDrop',
    AlertThresholdType.priceSpike => 'PriceSpike',
    AlertThresholdType.priceBelow => 'PriceBelow',
    AlertThresholdType.priceAbove => 'PriceAbove',
  };

  static AlertThresholdType _thresholdTypeFrom(String s) => switch (s) {
    'PriceSpike' => AlertThresholdType.priceSpike,
    'PriceBelow' => AlertThresholdType.priceBelow,
    'PriceAbove' => AlertThresholdType.priceAbove,
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
    return AlertItem(
      id: a.str('id'),
      kind: thresholdType == 'PriceSpike' || thresholdType == 'PriceAbove'
          ? AlertKind.spike
          : AlertKind.signal,
      isUnread: !(a.flag('isRead')),
      productName: product.str('name'),
      percentChange: a.numberOrNull('percentChange') ?? 0,
      previousPrice: a.numberOrNull('previousPrice') ?? 0,
      newPrice: a.numberOrNull('newPrice') ?? 0,
      locationName: location != null && location.isNotEmpty ? location : null,
      createdAt: a.date('triggeredAtUtc'),
      channel: null,
      opportunityId: null,
    );
  }
}
