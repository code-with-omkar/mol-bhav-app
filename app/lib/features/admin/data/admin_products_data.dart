import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_products.dart';

/// `GET /admin/catalog/products`, `GET` and `PUT /admin/catalog/products/{id}`.
@LazySingleton(as: AdminProductsRepository)
class AdminProductsRepositoryImpl implements AdminProductsRepository {
  AdminProductsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminProductSummary>>> getProducts({
    required int page,
    required int pageSize,
    String? search,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/catalog/products',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseSummary(row),
    ];
  });

  @override
  Future<Result<AdminProduct>> getProduct(String id) => runApiCall(() async {
    final j = (await _dio.get<Map<String, dynamic>>(
      '/admin/catalog/products/$id',
    )).data!;
    return parseProduct(j);
  });

  @override
  Future<Result<void>> updateProduct(AdminProduct product) =>
      runApiCall(() async {
        await _dio.put<void>(
          '/admin/catalog/products/${product.id}',
          data: {
            'subCategoryId': product.subCategoryId,
            'defaultUnitId': product.defaultUnitId,
            'displayOrder': product.displayOrder,
            'isActive': product.isActive,
            'imageKey': product.imageKey,
            'translations': [
              for (final t in product.translations)
                {
                  'languageCode': t.language,
                  'name': t.name,
                  'description': t.description,
                },
            ],
          },
        );
      });

  @override
  Future<Result<void>> createProduct({
    required String code,
    required String subCategoryId,
    required String unitId,
    required Map<String, String> names,
  }) => runApiCall(() async {
    await _dio.post<void>(
      '/admin/catalog/products',
      data: {
        'code': code.trim(),
        'subCategoryId': subCategoryId,
        'defaultUnitId': unitId,
        'displayOrder': 0,
        'translations': [
          for (final e in names.entries)
            if (e.value.trim().isNotEmpty)
              {'languageCode': e.key, 'name': e.value.trim()},
        ],
      },
    );
  });

  @override
  Future<Result<void>> addVariant({
    required String productId,
    required String code,
    required Map<String, String> names,
  }) => runApiCall(() async {
    await _dio.post<void>(
      '/admin/catalog/products/$productId/variants',
      data: {
        'code': code.trim(),
        'displayOrder': 0,
        'translations': [
          for (final e in names.entries)
            if (e.value.trim().isNotEmpty)
              {'languageCode': e.key, 'name': e.value.trim()},
        ],
      },
    );
  });

  @override
  Future<Result<void>> updateVariant({
    required String productId,
    required AdminVariant variant,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '/admin/catalog/products/$productId/variants/${variant.id}',
      data: {
        'displayOrder': variant.displayOrder,
        'isActive': variant.isActive,
        'translations': [
          for (final t in variant.translations)
            {
              'languageCode': t.language,
              'name': t.name,
              'description': t.description,
            },
        ],
      },
    );
  });

  static AdminProductSummary parseSummary(Map<String, dynamic> j) =>
      AdminProductSummary(
        id: j.str('id'),
        code: j.str('code'),
        name: j.str('name'),
        categoryCode: j.str('categoryCode'),
        subCategoryCode: j.str('subCategoryCode'),
        unitCode: j.str('defaultUnitCode'),
        isActive: j.flag('isActive'),
      );

  static List<ProductTranslation> _translations(Map<String, dynamic> j) =>
      j.list(
        'translations',
        (t) => ProductTranslation(
          language: t.str('languageCode'),
          name: t.str('name'),
          description: t.strOrNull('description'),
        ),
      );

  static AdminProduct parseProduct(Map<String, dynamic> j) => AdminProduct(
    id: j.str('id'),
    code: j.str('code'),
    subCategoryId: j.str('subCategoryId'),
    defaultUnitId: j.str('defaultUnitId'),
    displayOrder: j.integer('displayOrder'),
    isActive: j.flag('isActive'),
    imageKey: j.strOrNull('imageKey'),
    translations: _translations(j),
    variants: j.list(
      'variants',
      (v) => AdminVariant(
        id: v.str('id'),
        code: v.str('code'),
        displayOrder: v.integer('displayOrder'),
        isActive: v.flag('isActive'),
        translations: _translations(v),
      ),
    ),
  );
}
