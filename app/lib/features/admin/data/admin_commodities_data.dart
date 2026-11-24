import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_commodities.dart';

/// `GET /admin/catalog/categories` and `/units`, and
/// `POST /admin/catalog/products/import-feed`.
@LazySingleton(as: AdminCommoditiesRepository)
class AdminCommoditiesRepositoryImpl implements AdminCommoditiesRepository {
  AdminCommoditiesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<CommodityTargets>> getTargets() => runApiCall(() async {
    final categories = (await _dio.get<List<dynamic>>(
      '/admin/catalog/categories',
    )).data;
    final units = (await _dio.get<List<dynamic>>('/admin/catalog/units')).data;
    return parseTargets(
      (categories ?? const []).cast<Map<String, dynamic>>(),
      (units ?? const []).cast<Map<String, dynamic>>(),
    );
  });

  @override
  Future<Result<ImportCommoditiesResult>> importFeedProducts({
    required String sourceId,
    required String subCategoryId,
    required String unitId,
    required List<String> commodities,
  }) => runApiCall(() async {
    final j = (await _dio.post<Map<String, dynamic>>(
      '/admin/catalog/products/import-feed',
      data: {
        'priceSourceId': sourceId,
        'subCategoryId': subCategoryId,
        'defaultUnitId': unitId,
        'commodities': commodities,
      },
    )).data!;
    return parse(j);
  });

  static ImportCommoditiesResult parse(Map<String, dynamic> j) =>
      ImportCommoditiesResult(
        created: j.integer('created'),
        skipped: j.list(
          'skipped',
          (s) => SkippedCommodity(
            commodity: s.str('commodity'),
            reason: FeedCommoditySkipReason.fromWire(s.str('reason')),
          ),
        ),
      );

  /// Active sub-categories as "Category › Sub-category" and active units as
  /// "Name (symbol)", each in the English name (falling back to the code).
  static CommodityTargets parseTargets(
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> units,
  ) => CommodityTargets(
    subCategories: [
      for (final c in categories)
        if (c.flag('isActive'))
          for (final s in c.list('subCategories', (s) => s))
            if (s.flag('isActive'))
              CatalogChoice(
                id: s.str('id'),
                label: '${_name(c)} › ${_name(s)}',
              ),
    ],
    units: [
      for (final u in units)
        if (u.flag('isActive'))
          CatalogChoice(
            id: u.str('id'),
            label: '${_name(u)} (${u.str('symbol')})',
          ),
    ],
  );

  static String _name(Map<String, dynamic> j) {
    final translations = j.list('translations', (t) => t);
    for (final t in translations) {
      if (t.str('languageCode') == 'en') return t.str('name');
    }
    return translations.isNotEmpty
        ? translations.first.str('name')
        : j.str('code');
  }
}
