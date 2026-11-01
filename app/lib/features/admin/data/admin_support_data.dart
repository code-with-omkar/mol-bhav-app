import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../../support/data/support_data.dart';
import '../../support/domain/support.dart';
import '../domain/admin_support.dart';

/// `GET /admin/support/tickets`, `GET …/{id}`, `POST …/{id}/messages` and
/// `PUT …/{id}/status`. A ticket's conversation reads exactly as it does for
/// the user, so it shares that parsing.
@LazySingleton(as: AdminSupportRepository)
class AdminSupportRepositoryImpl implements AdminSupportRepository {
  AdminSupportRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminTicket>>> getTickets({
    TicketStatus? status,
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/support/tickets',
      queryParameters: {
        'status': ?status == null ? null : _statusWire(status),
        'page': page,
        'pageSize': pageSize,
      },
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseTicket(row),
    ];
  });

  @override
  Future<Result<SupportTicketThread>> getTicket(String ticketId) => runApiCall(
    () async => SupportRepositoryImpl.parseThread(
      (await _dio.get<Map<String, dynamic>>(
        '/admin/support/tickets/${Uri.encodeComponent(ticketId)}',
      )).data!,
    ),
  );

  @override
  Future<Result<void>> reply(String ticketId, String message) => runApiCall(
    () => _dio.post<void>(
      '/admin/support/tickets/${Uri.encodeComponent(ticketId)}/messages',
      data: {'message': message},
    ),
  );

  @override
  Future<Result<void>> setStatus(String ticketId, TicketStatus status) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/support/tickets/${Uri.encodeComponent(ticketId)}/status',
          data: {'status': _statusWire(status)},
        ),
      );

  static AdminTicket parseTicket(Map<String, dynamic> j) => AdminTicket(
    id: j.str('id'),
    userPhone: j.str('userPhoneNumberMasked'),
    category: SupportRepositoryImpl.parseCategory(j.strOrNull('category')),
    subject: j.str('subject'),
    status: SupportRepositoryImpl.parseStatus(j.strOrNull('status')),
    messageCount: j.integer('messageCount'),
    lastActivityAt: j.date('lastActivityAtUtc'),
  );

  static String _statusWire(TicketStatus status) => switch (status) {
    TicketStatus.open => 'Open',
    TicketStatus.inProgress => 'InProgress',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
  };
}
