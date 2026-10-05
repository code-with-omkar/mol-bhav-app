import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// How often a source is pulled. Matches the API's `IngestionScheduleFrequency`.
enum ScheduleFrequency {
  daily('Daily'),
  weekly('Weekly'),
  everyNHours('EveryNHours');

  const ScheduleFrequency(this.wire);

  final String wire;

  static ScheduleFrequency? fromWire(String? value) {
    for (final f in values) {
      if (f.wire == value) return f;
    }
    return null;
  }
}

/// Hours allowed for [ScheduleFrequency.everyNHours] — divisors of 24, so the
/// slots fall at the same clock times every day. Mirrors the API.
const allowedIntervalHours = [1, 2, 3, 4, 6, 8, 12];

/// API day names (`System.DayOfWeek`), Monday first, indexed by
/// `DateTime.weekday - 1`.
const scheduleDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

enum IngestionJobStatus { running, succeeded, partiallySucceeded, failed }

IngestionJobStatus parseJobStatus(String value) => switch (value) {
  'Running' => IngestionJobStatus.running,
  'Succeeded' => IngestionJobStatus.succeeded,
  'PartiallySucceeded' => IngestionJobStatus.partiallySucceeded,
  _ => IngestionJobStatus.failed,
};

class IngestionLastJob extends Equatable {
  const IngestionLastJob({
    required this.id,
    required this.isScheduled,
    this.isUpload = false,
    required this.status,
    required this.recordsPersisted,
    required this.recordsFailed,
    required this.startedAt,
    this.recordsUnchanged = 0,
    this.asOfDate,
    this.failureReason,
  });

  final String id;
  final bool isScheduled;

  /// Imported from an uploaded CSV rather than pulled from the API.
  final bool isUpload;
  final IngestionJobStatus status;
  final int recordsPersisted;
  final int recordsFailed;

  /// Rows already stored with the same figures (a re-run of a day).
  final int recordsUnchanged;
  final DateTime startedAt;

  /// The market day this run pulled (IST); null for old jobs.
  final DateTime? asOfDate;
  final String? failureReason;

  @override
  List<Object?> get props => [
    id,
    isScheduled,
    isUpload,
    status,
    recordsPersisted,
    recordsFailed,
    recordsUnchanged,
    startedAt,
    asOfDate,
    failureReason,
  ];
}

/// A procurement category (Agriculture, Construction, …) — sources, schedules
/// and uploads are grouped by it.
class AdminCategory extends Equatable {
  const AdminCategory({required this.code, required this.name});

  final String code;

  /// Localised by the API from `Accept-Language`.
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// One price source on the admin schedule screen.
class IngestionScheduleItem extends Equatable {
  const IngestionScheduleItem({
    required this.sourceId,
    required this.sourceCode,
    required this.sourceName,
    required this.sourceIsActive,
    required this.categoryCode,
    required this.categoryName,
    this.categoryDisplayOrder = 0,
    required this.isConfigured,
    required this.isEnabled,
    this.frequency,
    this.timeOfDay,
    this.dayOfWeek,
    this.intervalHours,
    this.nextRunAt,
    this.lastJob,
  });

  final String sourceId;
  final String sourceCode;
  final String sourceName;
  final bool sourceIsActive;

  /// The category this source prices; products from other categories in a
  /// run or upload are rejected row by row.
  final String categoryCode;
  final String categoryName;
  final int categoryDisplayOrder;

  /// False until an admin saves a schedule; such a source never runs on its own.
  final bool isConfigured;
  final bool isEnabled;
  final ScheduleFrequency? frequency;

  /// IST `HH:mm`.
  final String? timeOfDay;

  /// API day name, e.g. `Monday`.
  final String? dayOfWeek;
  final int? intervalHours;
  final DateTime? nextRunAt;
  final IngestionLastJob? lastJob;

  ScheduleInput toInput() => ScheduleInput(
    isEnabled: isConfigured ? isEnabled : true,
    frequency: frequency ?? ScheduleFrequency.daily,
    timeOfDay: timeOfDay ?? '18:00',
    dayOfWeek: dayOfWeek ?? scheduleDays.first,
    intervalHours: intervalHours ?? 6,
  );

  /// Prefill for the edit-source sheet.
  PriceSourceInput toSourceInput() => PriceSourceInput(
    code: sourceCode,
    name: sourceName,
    categoryCode: categoryCode,
    isActive: sourceIsActive,
  );

  @override
  List<Object?> get props => [
    sourceId,
    sourceCode,
    sourceName,
    sourceIsActive,
    categoryCode,
    categoryName,
    categoryDisplayOrder,
    isConfigured,
    isEnabled,
    frequency,
    timeOfDay,
    dayOfWeek,
    intervalHours,
    nextRunAt,
    lastJob,
  ];
}

/// What the editor saves. Day and interval are kept while the admin flips
/// between frequencies; only the ones the frequency uses are sent.
class ScheduleInput extends Equatable {
  const ScheduleInput({
    required this.isEnabled,
    required this.frequency,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.intervalHours,
  });

  final bool isEnabled;
  final ScheduleFrequency frequency;
  final String timeOfDay;
  final String dayOfWeek;
  final int intervalHours;

  ScheduleInput copyWith({
    bool? isEnabled,
    ScheduleFrequency? frequency,
    String? timeOfDay,
    String? dayOfWeek,
    int? intervalHours,
  }) => ScheduleInput(
    isEnabled: isEnabled ?? this.isEnabled,
    frequency: frequency ?? this.frequency,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    intervalHours: intervalHours ?? this.intervalHours,
  );

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'frequency': frequency.wire,
    'timeOfDay': timeOfDay,
    if (frequency == ScheduleFrequency.weekly) 'dayOfWeek': dayOfWeek,
    if (frequency == ScheduleFrequency.everyNHours)
      'intervalHours': intervalHours,
  };

  @override
  List<Object?> get props => [
    isEnabled,
    frequency,
    timeOfDay,
    dayOfWeek,
    intervalHours,
  ];
}

/// Create / edit a price source. The code is fixed after creation (adapters
/// and parsers are keyed by it); name, category and active flag can change.
class PriceSourceInput extends Equatable {
  const PriceSourceInput({
    required this.code,
    required this.name,
    required this.categoryCode,
    this.isActive = true,
  });

  final String code;
  final String name;
  final String categoryCode;
  final bool isActive;

  /// Lowercase letters, digits and hyphens — the code becomes the adapter /
  /// parser key and appears in URLs. Lengths mirror the API's `PricingRules`.
  static final codePattern = RegExp(r'^[a-z][a-z0-9-]*$');
  static const codeMaxLength = 40;
  static const nameMaxLength = 100;

  PriceSourceInput copyWith({
    String? code,
    String? name,
    String? categoryCode,
    bool? isActive,
  }) => PriceSourceInput(
    code: code ?? this.code,
    name: name ?? this.name,
    categoryCode: categoryCode ?? this.categoryCode,
    isActive: isActive ?? this.isActive,
  );

  Map<String, dynamic> toCreateJson() => {
    'code': code.trim().toLowerCase(),
    'name': name.trim(),
    'categoryCode': categoryCode,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name.trim(),
    'isActive': isActive,
    'categoryCode': categoryCode,
  };

  @override
  List<Object?> get props => [code, name, categoryCode, isActive];
}

/// Header row of the MolBhav standard price template — accepted for every
/// source and category. Mirrors the API's `StandardPriceCsvParser`.
const standardCsvHeader =
    'product_code,variant_code,location_kind,location_code,'
    'min_price,max_price,modal_price,arrival_qty,record_date';

/// Admin ingestion endpoints. Every call returns 403 for a non-admin token.
abstract interface class AdminIngestionRepository {
  /// Every source with its category, grouped by category on the server.
  Future<Result<List<IngestionScheduleItem>>> getSchedules();

  /// Active procurement categories, for the filter chips and source form.
  Future<Result<List<AdminCategory>>> getCategories();

  Future<Result<void>> createSource(PriceSourceInput input);

  Future<Result<void>> updateSource(String sourceId, PriceSourceInput input);

  /// Queues every active source of the category for yesterday's market day.
  /// Returns the number of sources queued; runs finish in the background.
  Future<Result<int>> runCategory(String categoryCode);

  Future<Result<void>> saveSchedule(String sourceId, ScheduleInput input);

  /// Starts a job now for yesterday's market day; it runs inside the request,
  /// so this returns when done.
  Future<Result<void>> runNow(String sourceId);

  /// Queues one run per day from [from] to [to] (inclusive, at most
  /// [maxBackfillDays]). Returns the number of days queued; the runs happen in
  /// the background and show up as the card's last run.
  Future<Result<int>> backfill(String sourceId, DateTime from, DateTime to);

  /// Imports a CSV — the MolBhav standard template (any source) or the
  /// source's own export where supported (Agmarknet). Runs inside the request;
  /// the result shows up as the card's last run.
  Future<Result<void>> uploadCsv(
    String sourceId,
    String fileName,
    List<int> bytes,
  );
}

/// Mirrors the API's upload limit.
const maxUploadBytes = 10 * 1024 * 1024;

/// Mirrors the API's `IngestionDates.MaxBackfillDays`.
const maxBackfillDays = 31;
