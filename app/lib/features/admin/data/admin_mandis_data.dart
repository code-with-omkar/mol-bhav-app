import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_mandis.dart';

/// `/admin/market/mandis` and `/admin/market/states`.
@LazySingleton(as: AdminMandisRepository)
class AdminMandisRepositoryImpl implements AdminMandisRepository {
  AdminMandisRepositoryImpl(this._dio);

  final Dio _dio;

  static const _mandis = '/admin/market/mandis';

  @override
  Future<Result<List<AdminMandi>>> getMandis({
    required int page,
    required int pageSize,
    String? search,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      _mandis,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseMandi(row),
    ];
  });

  @override
  Future<Result<List<DistrictChoice>>> getDistricts() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>('/admin/market/states')).data;
    return parseDistricts((rows ?? const []).cast<Map<String, dynamic>>());
  });

  @override
  Future<Result<void>> createMandi({
    required String code,
    required String name,
    required String districtId,
  }) => runApiCall(() async {
    await _dio.post<void>(
      _mandis,
      data: {
        'code': code.trim(),
        'districtId': districtId,
        'name': name.trim(),
      },
    );
  });

  @override
  Future<Result<void>> updateMandi({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '$_mandis/$id',
      data: {
        'districtId': districtId,
        'name': name.trim(),
        'isActive': isActive,
      },
    );
  });

  static AdminMandi parseMandi(Map<String, dynamic> j) => AdminMandi(
    id: j.str('id'),
    code: j.str('code'),
    name: j.str('name'),
    districtId: j.str('districtId'),
    districtName: j.str('districtName'),
    isActive: j.flag('isActive'),
  );

  /// Active districts of active states, as "State › District".
  static List<DistrictChoice> parseDistricts(
    List<Map<String, dynamic>> states,
  ) => [
    for (final s in states)
      if (s.flag('isActive'))
        for (final d in s.list('districts', (d) => d))
          if (d.flag('isActive'))
            DistrictChoice(
              id: d.str('id'),
              label: '${s.str('name')} › ${d.str('name')}',
            ),
  ];
}
