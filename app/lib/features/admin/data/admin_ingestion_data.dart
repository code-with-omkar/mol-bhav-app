import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_ingestion.dart';

/// - `GET /admin/ingestion/schedules` → `[AdminIngestionScheduleResponse]`
/// - `PUT /admin/ingestion/sources/{id}/schedule` → 204
/// - `POST /admin/ingestion/sources/{id}/run` → `{ id }` (job id)
@LazySingleton(as: AdminIngestionRepository)
class AdminIngestionRepositoryImpl implements AdminIngestionRepository {
  AdminIngestionRepositoryImpl(this._dio);

  final Dio _dio;

  /// A run pulls and saves a whole day of mandi prices inside the request.
  static const _runTimeout = Duration(minutes: 5);

  @override
  Future<Result<List<IngestionScheduleItem>>> getSchedules() => runApiCall(
    () async => parseList(
      (await _dio.get<List<dynamic>>('/admin/ingestion/schedules')).data ??
          const [],
      _item,
    ),
  );

  @override
  Future<Result<void>> saveSchedule(String sourceId, ScheduleInput input) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/ingestion/sources/$sourceId/schedule',
          data: input.toJson(),
        ),
      );

  @override
  Future<Result<void>> runNow(String sourceId) => runApiCall(
    () => _dio.post<void>(
      '/admin/ingestion/sources/$sourceId/run',
      options: Options(receiveTimeout: _runTimeout),
    ),
  );

  static IngestionScheduleItem _item(Map<String, dynamic> j) {
    final job = j.objOrNull('lastJob');
    return IngestionScheduleItem(
      sourceId: j.str('priceSourceId'),
      sourceCode: j.str('priceSourceCode'),
      sourceName: j.str('priceSourceName'),
      sourceIsActive: j.flag('priceSourceIsActive'),
      isConfigured: j.flag('isConfigured'),
      isEnabled: j.flag('isEnabled'),
      frequency: ScheduleFrequency.fromWire(j.strOrNull('frequency')),
      timeOfDay: j.strOrNull('timeOfDay'),
      dayOfWeek: j.strOrNull('dayOfWeek'),
      intervalHours: j.numberOrNull('intervalHours')?.toInt(),
      nextRunAt: j.dateOrNull('nextRunAtUtc'),
      lastJob: job == null
          ? null
          : IngestionLastJob(
              id: job.str('id'),
              isScheduled: job.str('triggerType') == 'Scheduled',
              status: parseJobStatus(job.str('status')),
              recordsPersisted: job.integer('recordsPersisted'),
              recordsFailed: job.integer('recordsFailed'),
              startedAt: job.date('startedAtUtc'),
              failureReason: job.strOrNull('failureReason'),
            ),
    );
  }
}
