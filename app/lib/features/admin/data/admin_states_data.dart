import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_states.dart';

/// `/admin/market/states` and its `/districts`.
@LazySingleton(as: AdminStatesRepository)
class AdminStatesRepositoryImpl implements AdminStatesRepository {
  AdminStatesRepositoryImpl(this._dio);

  final Dio _dio;

  static const _path = '/admin/market/states';

  @override
  Future<Result<List<AdminState>>> getStates() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(_path)).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseState(row),
    ];
  });

  @override
  Future<Result<void>> createState({
    required String name,
    required String code,
  }) => runApiCall(() async {
    await _dio.post<void>(
      _path,
      data: {'name': name.trim(), 'code': code.trim()},
    );
  });

  @override
  Future<Result<void>> updateState({
    required String id,
    required String name,
    required bool isActive,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '$_path/$id',
      data: {'name': name.trim(), 'isActive': isActive},
    );
  });

  @override
  Future<Result<void>> addDistrict({
    required String stateId,
    required String name,
  }) => runApiCall(() async {
    await _dio.post<void>(
      '$_path/$stateId/districts',
      data: {'name': name.trim()},
    );
  });

  @override
  Future<Result<void>> updateDistrict({
    required String stateId,
    required String id,
    required String name,
    required bool isActive,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '$_path/$stateId/districts/$id',
      data: {'name': name.trim(), 'isActive': isActive},
    );
  });

  static AdminState parseState(Map<String, dynamic> j) => AdminState(
    id: j.str('id'),
    name: j.str('name'),
    code: j.str('code'),
    isActive: j.flag('isActive'),
    districts: j.list(
      'districts',
      (d) => AdminDistrict(
        id: d.str('id'),
        name: d.str('name'),
        isActive: d.flag('isActive'),
      ),
    ),
  );
}
