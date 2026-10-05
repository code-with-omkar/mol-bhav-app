import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_ingestion.dart';

/// - `GET /admin/ingestion/schedules` → `[AdminIngestionScheduleResponse]` (with category)
/// - `GET /catalog/categories` → `[{ code, name, … }]`
/// - `POST /admin/pricing/sources` `{ code, name, categoryCode }` → 201
/// - `PUT /admin/pricing/sources/{id}` `{ name, isActive, categoryCode }` → 204
/// - `POST /admin/ingestion/categories/{code}/run` → 202 `{ categoryCode, sources, asOfDate }`
/// - `PUT /admin/ingestion/sources/{id}/schedule` → 204
/// - `POST /admin/ingestion/sources/{id}/run` → `{ id }` (job id)
/// - `POST /admin/ingestion/sources/{id}/upload` multipart `file` → 201 `{ id }`
/// - `POST /admin/ingestion/sources/{id}/backfill` `{ fromDate, toDate }` → 202 `{ days, fromDate, toDate }`
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
  Future<Result<List<AdminCategory>>> getCategories() => runApiCall(
    () async => parseList(
      (await _dio.get<List<dynamic>>('/catalog/categories')).data ?? const [],
      (j) => AdminCategory(code: j.str('code'), name: j.str('name')),
    ),
  );

  @override
  Future<Result<void>> createSource(PriceSourceInput input) => runApiCall(
    () => _dio.post<void>('/admin/pricing/sources', data: input.toCreateJson()),
  );

  @override
  Future<Result<void>> updateSource(String sourceId, PriceSourceInput input) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/pricing/sources/$sourceId',
          data: input.toUpdateJson(),
        ),
      );

  @override
  Future<Result<int>> runCategory(String categoryCode) => runApiCall(() async {
    final body =
        (await _dio.post<Map<String, dynamic>>(
          '/admin/ingestion/categories/${Uri.encodeComponent(categoryCode)}/run',
        )).data ??
        const <String, dynamic>{};
    return body.integer('sources');
  });

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

  @override
  Future<Result<int>> backfill(String sourceId, DateTime from, DateTime to) =>
      runApiCall(() async {
        final body =
            (await _dio.post<Map<String, dynamic>>(
              '/admin/ingestion/sources/$sourceId/backfill',
              data: {'fromDate': _day(from), 'toDate': _day(to)},
            )).data ??
            const <String, dynamic>{};
        return body.integer('days');
      });

  /// Parsing and saving a large file happens inside the request.
  static const _uploadTimeout = Duration(minutes: 5);

  @override
  Future<Result<void>> uploadCsv(
    String sourceId,
    String fileName,
    List<int> bytes,
  ) => runApiCall(
    () => _dio.post<void>(
      '/admin/ingestion/sources/$sourceId/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('text', 'csv'),
        ),
      }),
      options: Options(
        sendTimeout: _uploadTimeout,
        receiveTimeout: _uploadTimeout,
      ),
    ),
  );

  /// `yyyy-MM-dd` — the API takes calendar dates, not instants.
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static IngestionScheduleItem _item(Map<String, dynamic> j) {
    final job = j.objOrNull('lastJob');
    return IngestionScheduleItem(
      sourceId: j.str('priceSourceId'),
      sourceCode: j.str('priceSourceCode'),
      sourceName: j.str('priceSourceName'),
      sourceIsActive: j.flag('priceSourceIsActive'),
      categoryCode: j.str('categoryCode'),
      categoryName: j.str('categoryName'),
      categoryDisplayOrder:
          j.numberOrNull('categoryDisplayOrder')?.toInt() ?? 0,
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
              isUpload: job.str('triggerType') == 'Upload',
              status: parseJobStatus(job.str('status')),
              recordsPersisted: job.integer('recordsPersisted'),
              recordsFailed: job.integer('recordsFailed'),
              recordsUnchanged:
                  job.numberOrNull('recordsUnchanged')?.toInt() ?? 0,
              asOfDate: switch (job.strOrNull('asOfDate')) {
                final String d => DateTime.tryParse(d),
                null => null,
              },
              startedAt: job.date('startedAtUtc'),
              failureReason: job.strOrNull('failureReason'),
            ),
    );
  }
}
