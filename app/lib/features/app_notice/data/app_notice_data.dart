import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/app_notice.dart';

/// `GET /app-notice` (public), `GET /app-notice/admin` and `PUT /app-notice`
/// (admin).
@LazySingleton(as: AppNoticeRepository)
class AppNoticeRepositoryImpl implements AppNoticeRepository {
  AppNoticeRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AppNotice>> get() => _read('/app-notice');

  @override
  Future<Result<AppNotice>> getForEditing() => _read('/app-notice/admin');

  @override
  Future<Result<void>> save(AppNotice notice) => runApiCall(
    () => _dio.put<void>(
      '/app-notice',
      data: {
        'isActive': notice.isActive,
        'severity': notice.severity.wire,
        'message': notice.message.trim(),
      },
    ),
  );

  Future<Result<AppNotice>> _read(String path) => runApiCall(
    () async => parse((await _dio.get<Map<String, dynamic>>(path)).data!),
  );

  static AppNotice parse(Map<String, dynamic> j) => AppNotice(
    isActive: j.flag('isActive'),
    severity: NoticeSeverity.fromWire(j.str('severity')),
    message: j.str('message'),
  );
}
