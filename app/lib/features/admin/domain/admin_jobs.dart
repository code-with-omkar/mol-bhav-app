import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_ingestion.dart';

/// How a run started.
enum JobTrigger {
  scheduled,
  manual,
  upload;

  static JobTrigger fromWire(String value) => JobTrigger.values.firstWhere(
    (t) => t.name == value.toLowerCase(),
    orElse: () => manual,
  );
}

/// One price-feed run, from `GET /admin/ingestion/jobs`.
class AdminJob extends Equatable {
  const AdminJob({
    required this.id,
    required this.sourceCode,
    required this.trigger,
    required this.status,
    this.asOfDate,
    required this.fetched,
    required this.persisted,
    required this.unchanged,
    required this.failed,
    this.failureReason,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final String sourceCode;
  final JobTrigger trigger;
  final IngestionJobStatus status;

  /// The market day pulled.
  final DateTime? asOfDate;
  final int fetched;
  final int persisted;
  final int unchanged;
  final int failed;

  /// Set when the run could not even start fetching (e.g. the source was down).
  final String? failureReason;
  final DateTime startedAt;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
    id,
    sourceCode,
    trigger,
    status,
    asOfDate,
    fetched,
    persisted,
    unchanged,
    failed,
    failureReason,
    startedAt,
    completedAt,
  ];
}

/// A row of a run the source sent but we could not use.
class AdminJobError extends Equatable {
  const AdminJobError({
    required this.id,
    required this.message,
    required this.rawPayload,
    required this.occurredAt,
  });

  final String id;
  final String message;

  /// The source's record exactly as received (JSON text).
  final String rawPayload;
  final DateTime occurredAt;

  @override
  List<Object?> get props => [id, message, rawPayload, occurredAt];
}

/// Which runs the history shows.
enum JobListFilter {
  all,
  failed,
  partial,
  succeeded;

  /// The API's status value, or `null` for every run.
  String? get wire => switch (this) {
    JobListFilter.all => null,
    JobListFilter.failed => 'Failed',
    JobListFilter.partial => 'PartiallySucceeded',
    JobListFilter.succeeded => 'Succeeded',
  };
}

abstract interface class AdminJobsRepository {
  Future<Result<List<AdminJob>>> getJobs({
    JobListFilter filter = JobListFilter.all,
    required int page,
    required int pageSize,
  });

  Future<Result<AdminJob>> getJob(String jobId);

  Future<Result<List<AdminJobError>>> getErrors(
    String jobId, {
    required int page,
    required int pageSize,
  });
}
