import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/app_features.dart';

/// `GET /app-features` (public) and `PUT /app-features/{feature}` (admin).
@LazySingleton(as: AppFeaturesRepository)
class AppFeaturesRepositoryImpl implements AppFeaturesRepository {
  AppFeaturesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<Map<AppFeature, bool>>> getAll() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>('/app-features')).data ?? [];
    return parse(rows.cast<Map<String, dynamic>>());
  });

  @override
  Future<Result<void>> set(AppFeature feature, {required bool enabled}) =>
      runApiCall(
        () => _dio.put<void>(
          '/app-features/${feature.wire}',
          data: {'enabled': enabled},
        ),
      );

  /// Features this build knows, all on unless the API says otherwise.
  static Map<AppFeature, bool> parse(List<Map<String, dynamic>> rows) {
    final flags = {for (final f in AppFeature.values) f: true};
    for (final row in rows) {
      final feature = AppFeature.fromWire(row.str('feature'));
      if (feature != null) flags[feature] = row.flag('isEnabled');
    }
    return flags;
  }
}
