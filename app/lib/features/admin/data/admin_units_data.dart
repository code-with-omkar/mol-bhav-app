import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_products.dart';
import '../domain/admin_units.dart';

/// `/admin/catalog/units`.
@LazySingleton(as: AdminUnitsRepository)
class AdminUnitsRepositoryImpl implements AdminUnitsRepository {
  AdminUnitsRepositoryImpl(this._dio);

  final Dio _dio;

  static const _path = '/admin/catalog/units';

  @override
  Future<Result<List<AdminUnit>>> getUnits() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(_path)).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseUnit(row),
    ];
  });

  @override
  Future<Result<void>> createUnit({
    required String code,
    required String symbol,
    required UnitDimension dimension,
    required double toBaseFactor,
    required Map<String, String> names,
  }) => runApiCall(() async {
    await _dio.post<void>(
      _path,
      data: {
        'code': code.trim(),
        'symbol': symbol.trim(),
        'dimension': dimension.wire,
        'toBaseFactor': toBaseFactor,
        'translations': [
          for (final e in names.entries)
            if (e.value.trim().isNotEmpty)
              {'languageCode': e.key, 'name': e.value.trim()},
        ],
      },
    );
  });

  @override
  Future<Result<void>> updateUnit(AdminUnit unit) => runApiCall(() async {
    await _dio.put<void>(
      '$_path/${unit.id}',
      data: {
        'symbol': unit.symbol,
        'isActive': unit.isActive,
        'translations': [
          for (final t in unit.translations)
            {
              'languageCode': t.language,
              'name': t.name,
              'description': t.description,
            },
        ],
      },
    );
  });

  static AdminUnit parseUnit(Map<String, dynamic> j) => AdminUnit(
    id: j.str('id'),
    code: j.str('code'),
    symbol: j.str('symbol'),
    dimension: UnitDimension.fromWire(j.str('dimension')),
    toBaseFactor: j.number('toBaseFactor').toDouble(),
    isActive: j.flag('isActive'),
    translations: j.list(
      'translations',
      (t) => ProductTranslation(
        language: t.str('languageCode'),
        name: t.str('name'),
        description: t.strOrNull('description'),
      ),
    ),
  );
}
