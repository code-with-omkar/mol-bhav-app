import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/price_data_status.dart';

/// `GET /pricing/data-status` → `{ isDelayed, lastUpdatedAtUtc }`.
@LazySingleton(as: PriceDataStatusRepository)
class PriceDataStatusRepositoryImpl implements PriceDataStatusRepository {
  PriceDataStatusRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<PriceDataStatus>> getStatus() => runApiCall(() async {
    final json = (await _dio.get<Map<String, dynamic>>('/pricing/data-status'))
        .data!;
    return PriceDataStatus(
      isDelayed: json.flag('isDelayed'),
      lastUpdatedAt: json.dateOrNull('lastUpdatedAtUtc'),
    );
  });
}
