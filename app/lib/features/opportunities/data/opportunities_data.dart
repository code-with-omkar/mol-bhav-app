import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/opportunities.dart';

/// - `GET /opportunities?page=&pageSize=` → `[MarketOpportunityResponse]`
/// - `GET /opportunities/{id}` → `{opportunity, markets, referenceQuantity}`
/// - `POST /opportunities/{id}/read`
abstract interface class OpportunitiesRemoteDataSource {
  Future<List<dynamic>> getOpportunities(int page, int pageSize);

  Future<Map<String, dynamic>> getOpportunity(String id);

  Future<void> markRead(String id);
}

@LazySingleton(as: OpportunitiesRemoteDataSource)
class DioOpportunitiesRemoteDataSource
    implements OpportunitiesRemoteDataSource {
  DioOpportunitiesRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<dynamic>> getOpportunities(int page, int pageSize) async =>
      (await _dio.get<List<dynamic>>(
        '/opportunities',
        queryParameters: {'page': page, 'pageSize': pageSize},
      )).data ??
      const [];

  @override
  Future<Map<String, dynamic>> getOpportunity(String id) async =>
      (await _dio.get<Map<String, dynamic>>(
        '/opportunities/${Uri.encodeComponent(id)}',
      )).data!;

  @override
  Future<void> markRead(String id) =>
      _dio.post<void>('/opportunities/${Uri.encodeComponent(id)}/read');
}

@LazySingleton(as: OpportunitiesRepository)
class OpportunitiesRepositoryImpl implements OpportunitiesRepository {
  OpportunitiesRepositoryImpl(this._remote, this._cache);

  final OpportunitiesRemoteDataSource _remote;
  final ResponseCache _cache;

  static const recentKey = 'opportunities.recent';

  @override
  Future<Result<List<MarketOpportunity>>> getRecent() => runCachedApiCall(
    cache: _cache,
    key: recentKey,
    fetch: () => _remote.getOpportunities(1, 20),
    parse: (json) => parseList(json as List<dynamic>, parseOpportunity),
  );

  @override
  Future<Result<OpportunityDetail>> getDetail(String id) async {
    final result = await runApiCall(() async {
      final json = await _remote.getOpportunity(id);
      return OpportunityDetail(
        opportunity: parseOpportunity(json.obj('opportunity')),
        markets: json.list(
          'markets',
          (m) => OpportunityMarket(
            id: m.str('locationId'),
            name: m.str('name'),
            district: m.strOrNull('districtName') ?? '',
            price: m.number('modalPrice'),
            landedPrice: m.number('landedPrice'),
            isHomeDistrict: m.flag('isHomeDistrict'),
          ),
        ),
        referenceQuantity: json.numberOrNull('referenceQuantity') ?? 1,
      );
    });
    if (result case Ok(:final value) when !value.opportunity.isRead) {
      // Opening it reads it; the lists pick that up on their next load.
      unawaited(
        runApiCall(() => _remote.markRead(id))
            .then((_) => _cache.invalidate(const [recentKey])),
      );
    }
    return result;
  }

  /// Shared with the alerts list, which shows opportunities in its inbox.
  static MarketOpportunity parseOpportunity(Map<String, dynamic> o) {
    final product = o.obj('product');
    final home = o.obj('home');
    final best = o.obj('best');
    final variant = o.strOrNull('variantName');
    return MarketOpportunity(
      id: o.str('id'),
      productId: product.str('id'),
      productName: product.str('name'),
      variantName: variant != null && variant.isNotEmpty ? variant : null,
      unit: product.obj('defaultUnit').str('symbol'),
      homeId: home.str('locationId'),
      homeName: home.str('name'),
      homePrice: home.number('price'),
      bestId: best.str('locationId'),
      bestName: best.str('name'),
      bestDistrict: best.strOrNull('districtName') ?? '',
      bestPrice: best.number('price'),
      landedPrice: o.number('landedPrice'),
      savingsPercent: o.number('savingsPercent'),
      savingsPerUnit: o.number('savingsPerUnit'),
      priceDate: DateTime.parse(o.str('priceDate')),
      detectedAt: o.date('detectedAtUtc'),
      isRead: o.flag('isRead'),
    );
  }
}
