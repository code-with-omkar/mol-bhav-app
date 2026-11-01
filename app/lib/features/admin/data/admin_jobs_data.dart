import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_ingestion.dart';
import '../domain/admin_jobs.dart';

/// `GET /admin/ingestion/jobs`, `/jobs/{id}` and `/jobs/{id}/errors`.
@LazySingleton(as: AdminJobsRepository)
class AdminJobsRepositoryImpl implements AdminJobsRepository {
  AdminJobsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminJob>>> getJobs({
    JobListFilter filter = JobListFilter.all,
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final data = (await _dio.get<List<dynamic>>(
      '/admin/ingestion/jobs',
      queryParameters: {
        'status': ?filter.wire,
        'page': page,
        'pageSize': pageSize,
      },
    )).data;
    return parseList(data ?? const [], parseJob);
  });

  @override
  Future<Result<AdminJob>> getJob(String jobId) => runApiCall(() async {
    final j = (await _dio.get<Map<String, dynamic>>(
      '/admin/ingestion/jobs/${Uri.encodeComponent(jobId)}',
    )).data!;
    return parseJob(j);
  });

  @override
  Future<Result<List<AdminJobError>>> getErrors(
    String jobId, {
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final data = (await _dio.get<List<dynamic>>(
      '/admin/ingestion/jobs/${Uri.encodeComponent(jobId)}/errors',
      queryParameters: {'page': page, 'pageSize': pageSize},
    )).data;
    return parseList(data ?? const [], parseError);
  });

  static AdminJob parseJob(Map<String, dynamic> j) => AdminJob(
    id: j.str('id'),
    sourceCode: j.str('priceSourceCode'),
    trigger: JobTrigger.fromWire(j.str('triggerType')),
    status: parseJobStatus(j.str('status')),
    asOfDate: switch (j.strOrNull('asOfDate')) {
      final String d => DateTime.tryParse(d),
      null => null,
    },
    fetched: j.integer('recordsFetched'),
    persisted: j.integer('recordsPersisted'),
    unchanged: j.integer('recordsUnchanged'),
    failed: j.integer('recordsFailed'),
    failureReason: j.strOrNull('failureReason'),
    startedAt: j.date('startedAtUtc'),
    completedAt: j.dateOrNull('completedAtUtc'),
  );

  static AdminJobError parseError(Map<String, dynamic> j) => AdminJobError(
    id: j.str('id'),
    message: j.str('errorMessage'),
    rawPayload: j['rawPayload']?.toString() ?? '',
    occurredAt: j.date('occurredAtUtc'),
  );
}
