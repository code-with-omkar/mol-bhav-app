import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/suppliers.dart';

/// `/market/suppliers`.
@LazySingleton(as: SuppliersRepository)
class SuppliersRepositoryImpl implements SuppliersRepository {
  SuppliersRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Supplier>>> getSuppliers({
    required int page,
    required int pageSize,
    String? search,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/market/suppliers',
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

  static Supplier parseSupplier(Map<String, dynamic> j) => Supplier(
    id: j.str('id'),
    name: j.str('name'),
    districtName: j.str('districtName'),
    stateName: j.str('stateName'),
    contactPhone: j.strOrNull('contactPhone'),
  );
}
