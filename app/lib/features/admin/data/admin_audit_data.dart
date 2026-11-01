import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_audit.dart';

/// `GET /admin/audit?page=&pageSize=`.
@LazySingleton(as: AdminAuditRepository)
class AdminAuditRepositoryImpl implements AdminAuditRepository {
  AdminAuditRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AuditEntry>>> getEntries({
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/audit',
      queryParameters: {'page': page, 'pageSize': pageSize},
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parse(row),
    ];
  });

  static AuditEntry parse(Map<String, dynamic> j) {
    String? text(String key) {
      final v = j[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return AuditEntry(
      id: j.str('id'),
      occurredAt: DateTime.parse(j.str('occurredAtUtc')).toLocal(),
      action: j.str('action'),
      summary: j.str('summary'),
      target: text('target'),
      actorName: text('actorName'),
    );
  }
}
