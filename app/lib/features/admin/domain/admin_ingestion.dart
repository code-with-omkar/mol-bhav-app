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
    required this.status,
    required this.recordsPersisted,
    required this.recordsFailed,
    required this.startedAt,
    this.failureReason,
  });

  final String id;
  final bool isScheduled;
  final IngestionJobStatus status;
  final int recordsPersisted;
  final int recordsFailed;
  final DateTime startedAt;
  final String? failureReason;

  @override
  List<Object?> get props => [
    id,
    isScheduled,
    status,
    recordsPersisted,
    recordsFailed,
    startedAt,
    failureReason,
  ];
}

/// One price source on the admin schedule screen.
class IngestionScheduleItem extends Equatable {
  const IngestionScheduleItem({
    required this.sourceId,
    required this.sourceCode,
    required this.sourceName,
    required this.sourceIsActive,
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

  @override
  List<Object?> get props => [
    sourceId,
    sourceCode,
    sourceName,
    sourceIsActive,
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

/// Admin ingestion endpoints. Every call returns 403 for a non-admin token.
abstract interface class AdminIngestionRepository {
  Future<Result<List<IngestionScheduleItem>>> getSchedules();

  Future<Result<void>> saveSchedule(String sourceId, ScheduleInput input);

  /// Starts a job now; it runs inside the request, so this returns when done.
  Future<Result<void>> runNow(String sourceId);
}
