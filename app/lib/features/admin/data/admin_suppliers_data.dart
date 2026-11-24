import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_suppliers.dart';

/// `/admin/market/suppliers`.
@LazySingleton(as: AdminSuppliersRepository)
class AdminSuppliersRepositoryImpl implements AdminSuppliersRepository {
  AdminSuppliersRepositoryImpl(this._dio);

  final Dio _dio;

  static const _path = '/admin/market/suppliers';

  @override
  Future<Result<List<AdminSupplier>>> getSuppliers({
    required int page,
    required int pageSize,
    String? search,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      _path,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseSupplier(row),
    ];
  });

  @override
  Future<Result<void>> createSupplier({
    required String code,
    required String name,
    required String districtId,
    String? contactPhone,
  }) => runApiCall(() async {
    await _dio.post<void>(
      _path,
      data: {
        'code': code.trim(),
        'districtId': districtId,
        'name': name.trim(),
        'contactPhone': _phone(contactPhone),
      },
    );
  });

  @override
  Future<Result<void>> updateSupplier({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
    String? contactPhone,
  }) => runApiCall(() async {
    await _dio.put<void>(
      '$_path/$id',
      data: {
        'districtId': districtId,
        'name': name.trim(),
        'contactPhone': _phone(contactPhone),
        'isActive': isActive,
      },
    );
  });

  /// A blank phone is sent as no phone.
  static String? _phone(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  static AdminSupplier parseSupplier(Map<String, dynamic> j) => AdminSupplier(
    id: j.str('id'),
    code: j.str('code'),
    name: j.str('name'),
    districtId: j.str('districtId'),
    districtName: j.str('districtName'),
    contactPhone: j.strOrNull('contactPhone'),
    isActive: j.flag('isActive'),
  );
}
