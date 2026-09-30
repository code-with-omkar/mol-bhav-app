import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/mandi_prices.dart';

/// - `GET /market/states`, `/market/states/{id}/districts`, `/market/mandis?districtId=`
/// - `GET /pricing/latest-by-location?locationKind=Mandi&locationId=`
@LazySingleton(as: MandiPricesRepository)
class MandiPricesRepositoryImpl implements MandiPricesRepository {
  MandiPricesRepositoryImpl(this._dio, this._cache);

  static const _pageSize = 100;

  final Dio _dio;
  final ResponseCache _cache;

  /// States, districts and mandis change rarely: served from the cache for a day.
  Future<Result<List<LocationOption>>> _reference(
    String key,
    String path, [
    Map<String, dynamic>? query,
  ]) => runCachedApiCall(
    cache: _cache,
    key: key,
    ttl: referenceDataTtl,
    fetch: () => _list(path, query),
    parse: (json) => _options([
      for (final e in json as List<dynamic>) e as Map<String, dynamic>,
    ]),
  );

  Future<List<Map<String, dynamic>>> _list(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final data = (await _dio.get<List<dynamic>>(
      path,
      queryParameters: query,
    )).data;
    return [for (final e in data ?? const []) e as Map<String, dynamic>];
  }

  static List<LocationOption> _options(List<Map<String, dynamic>> rows) => [
    for (final r in rows) LocationOption(id: r.str('id'), name: r.str('name')),
  ];

  @override
  Future<Result<List<LocationOption>>> getStates() =>
      _reference('market.states', '/market/states');

  @override
  Future<Result<List<LocationOption>>> getDistricts(String stateId) =>
      _reference(
        'market.districts.$stateId',
        '/market/states/${Uri.encodeComponent(stateId)}/districts',
      );

  @override
  Future<Result<List<LocationOption>>> getMandis(String districtId) =>
      _reference('market.mandis.$districtId', '/market/mandis', {
        'districtId': districtId,
        'pageSize': _pageSize,
      });

  @override
  Future<Result<List<MandiPrice>>> getPrices(String mandiId) => runApiCall(
    () async => [
      for (final r in await _list('/pricing/latest-by-location', {
        'locationKind': 'Mandi',
        'locationId': mandiId,
        'pageSize': _pageSize,
      }))
        MandiPrice(
          productId: r.str('productId'),
          productName: r.str('productName'),
          variantId: r.strOrNull('variantId'),
          variantName: r.strOrNull('variantName'),
          modalPrice: r.number('modalPrice'),
          minPrice: r['minPrice'] as num?,
          maxPrice: r['maxPrice'] as num?,
          unitSymbol: r.str('unitSymbol'),
          recordDate: DateTime.parse(r.str('recordDate')),
          source: r.str('sourceName'),
        ),
    ],
  );
}
