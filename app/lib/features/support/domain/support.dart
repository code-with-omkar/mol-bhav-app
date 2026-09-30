import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

enum TicketCategory { account, payment, data, other }

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketAuthor { user, admin }

/// One question and its answer, as seeded in the API's LocalizedTexts store.
class FaqEntry extends Equatable {
  const FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  List<Object?> get props => [question, answer];
}

/// The channels the Help & Support screen offers before a ticket is raised.
class SupportContact extends Equatable {
  const SupportContact({
    required this.whatsAppNumber,
    required this.phone,
    required this.email,
  });

  /// E.164 digits with no `+`, ready for a `wa.me` link.
  final String whatsAppNumber;
  final String phone;
  final String email;

  @override
  List<Object?> get props => [whatsAppNumber, phone, email];
}

class SupportTicketSummary extends Equatable {
  const SupportTicketSummary({
    required this.id,
    required this.category,
    required this.subject,
    required this.status,
    required this.messageCount,
    required this.createdAt,
    required this.lastActivityAt,
  });

  final String id;
  final TicketCategory? category;
  final String subject;
  final TicketStatus status;
  final int messageCount;
  final DateTime createdAt;

  /// Newest message or status change — the list is ordered by it.
  final DateTime lastActivityAt;

  @override
  List<Object?> get props => [
    id,
    category,
    subject,
    status,
    messageCount,
    createdAt,
    lastActivityAt,
  ];
}

class SupportTicketMessage extends Equatable {
  const SupportTicketMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final TicketAuthor author;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, author, body, createdAt];
}

class SupportTicketThread extends Equatable {
  const SupportTicketThread({
    required this.id,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastActivityAt,
    required this.messages,
  });

  final String id;
  final TicketCategory? category;
  final String subject;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime lastActivityAt;

  /// Oldest first, as the API returns them.
  final List<SupportTicketMessage> messages;

  /// A closed ticket takes no further replies (the API refuses them).
  bool get canReply => status != TicketStatus.closed;

  @override
  List<Object?> get props => [
    id,
    category,
    subject,
    status,
    createdAt,
    lastActivityAt,
    messages,
  ];
}

class NewTicket extends Equatable {
  const NewTicket({
    required this.category,
    required this.subject,
    required this.message,
  });

  final TicketCategory category;
  final String subject;
  final String message;

  @override
  List<Object?> get props => [category, subject, message];
}

abstract interface class SupportRepository {
  /// FAQ and contact details are reference data: cached for a day.
  Future<Result<List<FaqEntry>>> getFaq();

  Future<Result<SupportContact>> getContact();

  Future<Result<List<SupportTicketSummary>>> getTickets();

  Future<Result<SupportTicketThread>> getTicket(String ticketId);

  /// Returns the new ticket's id, so the caller can open its thread.
  Future<Result<String>> createTicket(NewTicket ticket);

  Future<Result<void>> reply(String ticketId, String message);
}

@injectable
class GetSupportFaq {
  const GetSupportFaq(this._repository);

  final SupportRepository _repository;

  Future<Result<List<FaqEntry>>> call() => _repository.getFaq();
}

@injectable
class GetSupportContact {
  const GetSupportContact(this._repository);

  final SupportRepository _repository;

  Future<Result<SupportContact>> call() => _repository.getContact();
}

@injectable
class GetSupportTickets {
  const GetSupportTickets(this._repository);

  final SupportRepository _repository;

  Future<Result<List<SupportTicketSummary>>> call() => _repository.getTickets();
}

@injectable
class GetSupportTicket {
  const GetSupportTicket(this._repository);

  final SupportRepository _repository;

  Future<Result<SupportTicketThread>> call(String ticketId) =>
      _repository.getTicket(ticketId);
}

@injectable
class CreateSupportTicket {
  const CreateSupportTicket(this._repository);

  final SupportRepository _repository;

  Future<Result<String>> call(NewTicket ticket) =>
      _repository.createTicket(ticket);
}

@injectable
class ReplyToSupportTicket {
  const ReplyToSupportTicket(this._repository);

  final SupportRepository _repository;

  Future<Result<void>> call(String ticketId, String message) =>
      _repository.reply(ticketId, message);
}
