import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_categories.dart';
import '../domain/admin_products.dart';

/// `/admin/catalog/categories` and its `/sub-categories`.
@LazySingleton(as: AdminCategoriesRepository)
class AdminCategoriesRepositoryImpl implements AdminCategoriesRepository {
  AdminCategoriesRepositoryImpl(this._dio);

  final Dio _dio;

  static const _path = '/admin/catalog/categories';

  @override
  Future<Result<List<AdminCategory>>> getCategories() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(_path)).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseCategory(row),
    ];
  });

  @override
  Future<Result<void>> createCategory({
    required String code,
    required Map<String, String> names,
  }) => runApiCall(() async {
    await _dio.post<void>(
      _path,
      data: {
        'code': code.trim(),
        'displayOrder': 0,
        'translations': _namesJson(names),
      },
    );
  });

  @override
  Future<Result<void>> updateCategory(AdminCategory category) =>
      runApiCall(() async {
        await _dio.put<void>(
          '$_path/${category.id}',
          data: {
            'iconKey': category.iconKey,
            'displayOrder': category.displayOrder,
            'isActive': category.isActive,
            'translations': _translationsJson(category.translations),
          },
        );
      });

  @override
  Future<Result<void>> addSubCategory({
    required String categoryId,
    required String code,
    required Map<String, String> names,
  }) => runApiCall(() async {
    await _dio.post<void>(
      '$_path/$categoryId/sub-categories',
      data: {
        'code': code.trim(),
        'displayOrder': 0,
        'translations': _namesJson(names),
      },
    );
  });

  @override
  Future<Result<void>> updateSubCategory({
    required String categoryId,
    required AdminSubCategory subCategory,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '$_path/$categoryId/sub-categories/${subCategory.id}',
      data: {
        'displayOrder': subCategory.displayOrder,
        'isActive': subCategory.isActive,
        'translations': _translationsJson(subCategory.translations),
      },
    );
  });

  static List<Map<String, dynamic>> _namesJson(Map<String, String> names) => [
    for (final e in names.entries)
      if (e.value.trim().isNotEmpty)
        {'languageCode': e.key, 'name': e.value.trim()},
  ];

  static List<Map<String, dynamic>> _translationsJson(
    List<ProductTranslation> translations,
  ) => [
    for (final t in translations)
      {
        'languageCode': t.language,
        'name': t.name,
        'description': t.description,
      },
  ];

  static List<ProductTranslation> _translations(Map<String, dynamic> j) =>
      j.list(
        'translations',
        (t) => ProductTranslation(
          language: t.str('languageCode'),
          name: t.str('name'),
          description: t.strOrNull('description'),
        ),
      );

  static AdminCategory parseCategory(Map<String, dynamic> j) => AdminCategory(
    id: j.str('id'),
    code: j.str('code'),
    iconKey: j.strOrNull('iconKey'),
    displayOrder: j.integer('displayOrder'),
    isActive: j.flag('isActive'),
    translations: _translations(j),
    subCategories: j.list(
      'subCategories',
      (s) => AdminSubCategory(
        id: s.str('id'),
        code: s.str('code'),
        displayOrder: s.integer('displayOrder'),
        isActive: s.flag('isActive'),
        translations: _translations(s),
      ),
    ),
  );
}
