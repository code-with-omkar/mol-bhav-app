import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/catalog.dart';

/// - `GET /catalog/categories`
/// - `GET /catalog/categories/{code}/products?search=&pageSize=`
/// - `GET /catalog/products/{id}` (with variants)
@LazySingleton(as: CatalogRepository)
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._dio, this._cache);

  final Dio _dio;
  final ResponseCache _cache;

  static const _pageSize = 100;

  @override
  Future<Result<List<CatalogCategory>>> getCategories() => runCachedApiCall(
    cache: _cache,
    key: 'catalog.categories',
    ttl: referenceDataTtl,
    fetch: () async =>
        (await _dio.get<List<dynamic>>('/catalog/categories')).data ?? [],
    parse: (json) => parseList(
      json as List<dynamic>,
      (c) => CatalogCategory(code: c.str('code'), name: c.str('name')),
    ),
  );

  @override
  Future<Result<List<CatalogProduct>>> getProducts(
    String categoryCode, {
    String search = '',
  }) {
    final term = search.trim();
    Future<List<dynamic>> fetch() async =>
        (await _dio.get<List<dynamic>>(
          '/catalog/categories/${Uri.encodeComponent(categoryCode)}/products',
          queryParameters: {
            'search': ?(term.isEmpty ? null : term),
            'pageSize': _pageSize,
          },
        )).data ??
        [];
    List<CatalogProduct> parse(Object json) =>
        parseList(json as List<dynamic>, _product);

    // The unfiltered list is reference data; searches always go live.
    return term.isEmpty
        ? runCachedApiCall(
            cache: _cache,
            key: 'catalog.products.$categoryCode',
            ttl: referenceDataTtl,
            fetch: fetch,
            parse: parse,
          )
        : runApiCall(() async => parse(await fetch()));
  }

  @override
  Future<Result<CatalogProductDetail>> getProduct(String id) =>
      runCachedApiCall(
        cache: _cache,
        key: 'catalog.product.$id',
        ttl: referenceDataTtl,
        fetch: () async => (await _dio.get<Map<String, dynamic>>(
          '/catalog/products/${Uri.encodeComponent(id)}',
        )).data!,
        parse: (json) {
          final j = json as Map<String, dynamic>;
          return CatalogProductDetail(
            product: CatalogProduct(
              id: j.str('id'),
              name: j.str('name'),
              subCategoryName: j.obj('subCategory').str('name'),
              defaultUnit: _unit(j.obj('defaultUnit')),
            ),
            variants: j.list(
              'variants',
              (v) => CatalogVariant(id: v.str('id'), name: v.str('name')),
            ),
          );
        },
      );

  static CatalogProduct _product(Map<String, dynamic> j) => CatalogProduct(
    id: j.str('id'),
    name: j.str('name'),
    subCategoryName: j.strOrNull('subCategoryName') ?? '',
    defaultUnit: _unit(j.obj('defaultUnit')),
  );

  static CatalogUnit _unit(Map<String, dynamic> u) => CatalogUnit(
    id: u.str('id'),
    code: u.str('code'),
    symbol: u.str('symbol'),
    name: u.strOrNull('name') ?? u.str('symbol'),
  );
}
