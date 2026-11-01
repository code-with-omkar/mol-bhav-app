import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import '../../support/domain/support.dart';

/// One row of the admin support queue (`GET /admin/support/tickets`). It
/// carries the owner (phone number masked by the API) so the queue can be
/// worked without opening every ticket.
class AdminTicket extends Equatable {
  const AdminTicket({
    required this.id,
    required this.userPhone,
    required this.category,
    required this.subject,
    required this.status,
    required this.messageCount,
    required this.lastActivityAt,
  });

  final String id;

  /// Already masked by the API, e.g. `+91 98•••••210`.
  final String userPhone;

  /// Null for a category this build does not know.
  final TicketCategory? category;
  final String subject;
  final TicketStatus status;
  final int messageCount;

  /// The queue is ordered by it, newest first.
  final DateTime lastActivityAt;

  @override
  List<Object?> get props => [
    id,
    userPhone,
    category,
    subject,
    status,
    messageCount,
    lastActivityAt,
  ];
}

/// The statuses an admin may set. A closed ticket is final, so the API
/// refuses any change from it.
const settableStatuses = [
  TicketStatus.open,
  TicketStatus.inProgress,
  TicketStatus.resolved,
  TicketStatus.closed,
];

abstract interface class AdminSupportRepository {
  /// Tickets newest activity first; [status] narrows them, null = all.
  Future<Result<List<AdminTicket>>> getTickets({
    TicketStatus? status,
    required int page,
    required int pageSize,
  });

  /// One ticket with its whole conversation, oldest message first.
  Future<Result<SupportTicketThread>> getTicket(String ticketId);

  /// Support's reply; moves an Open ticket to In progress and tells the owner.
  Future<Result<void>> reply(String ticketId, String message);

  Future<Result<void>> setStatus(String ticketId, TicketStatus status);
}
