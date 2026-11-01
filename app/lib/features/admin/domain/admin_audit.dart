import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// One recorded admin action (`GET /admin/audit`). The wording comes from the
/// API in English: it is a record for admins, not app text.
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.occurredAt,
    required this.action,
    required this.summary,
    this.target,
    this.actorName,
  });

  final String id;
  final DateTime occurredAt;

  /// `Area.Verb`, e.g. `User.Suspend`.
  final String action;
  final String summary;

  /// The record acted on (an id or a name), if any.
  final String? target;

  /// Who did it; null when that account no longer exists.
  final String? actorName;

  /// `User.Suspend` → `User`.
  String get area => action.split('.').first;

  @override
  List<Object?> get props => [
    id,
    occurredAt,
    action,
    summary,
    target,
    actorName,
  ];
}

abstract interface class AdminAuditRepository {
  /// Entries newest first.
  Future<Result<List<AuditEntry>>> getEntries({
    required int page,
    required int pageSize,
  });
}
