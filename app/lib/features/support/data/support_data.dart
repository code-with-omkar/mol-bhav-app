import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/support.dart';

/// Support endpoints:
///
/// - `GET /localization/texts?keyPrefix=support.faq.` → `{ "support.faq.1.q": …, "support.faq.1.a": … }`
/// - `GET /support/contact` → `{ whatsAppNumber, phone, email }`
/// - `GET /support/tickets?page=&pageSize=` → paged `[SupportTicketSummaryResponse]`
/// - `GET /support/tickets/{id}` → the ticket with its message thread
/// - `POST /support/tickets` `{ category, subject, message }` → `{ id }`
/// - `POST /support/tickets/{id}/messages` `{ message }`
@LazySingleton(as: SupportRepository)
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._dio, this._cache);

  final Dio _dio;
  final ResponseCache _cache;

  static const _faqPrefix = 'support.faq.';
  static const _pageSize = 50;

  /// Highest FAQ number the app looks for. The API seeds ten; a gap simply
  /// ends the list, so adding an eleventh needs no app change until this rises.
  static const _maxFaqEntries = 30;

  @override
  Future<Result<List<FaqEntry>>> getFaq() => runCachedApiCall(
    cache: _cache,
    key: 'support.faq',
    ttl: referenceDataTtl,
    fetch: () async =>
        (await _dio.get<Map<String, dynamic>>(
          '/localization/texts',
          queryParameters: {'keyPrefix': _faqPrefix},
        )).data ??
        const <String, dynamic>{},
    parse: (json) {
      final texts = json as Map<String, dynamic>;
      // Numbered keys, so the order is the one support intended — a map's is not.
      return [
        for (var i = 1; i <= _maxFaqEntries; i++)
          if (texts['$_faqPrefix$i.q'] case final String question)
            if (texts['$_faqPrefix$i.a'] case final String answer)
              FaqEntry(question: question, answer: answer),
      ];
    },
  );

  @override
  Future<Result<SupportContact>> getContact() => runCachedApiCall(
    cache: _cache,
    key: 'support.contact',
    ttl: referenceDataTtl,
    fetch: () async =>
        (await _dio.get<Map<String, dynamic>>('/support/contact')).data ??
        const <String, dynamic>{},
    parse: (json) {
      final j = json as Map<String, dynamic>;
      return SupportContact(
        whatsAppNumber: j.strOrNull('whatsAppNumber') ?? '',
        phone: j.strOrNull('phone') ?? '',
        email: j.strOrNull('email') ?? '',
      );
    },
  );

  @override
  Future<Result<List<SupportTicketSummary>>> getTickets() => runApiCall(
    () async => parseList(
      (await _dio.get<List<dynamic>>(
            '/support/tickets',
            queryParameters: {'pageSize': _pageSize},
          )).data ??
          const [],
      _summary,
    ),
  );

  @override
  Future<Result<SupportTicketThread>> getTicket(String ticketId) => runApiCall(
    () async => _thread(
      (await _dio.get<Map<String, dynamic>>(
        '/support/tickets/${Uri.encodeComponent(ticketId)}',
      )).data!,
    ),
  );

  @override
  Future<Result<String>> createTicket(NewTicket ticket) => runApiCall(() async {
    final body = (await _dio.post<Map<String, dynamic>>(
      '/support/tickets',
      data: {
        'category': _categoryName(ticket.category),
        'subject': ticket.subject,
        'message': ticket.message,
      },
    )).data!;
    return body.str('id');
  });

  @override
  Future<Result<void>> reply(String ticketId, String message) => runApiCall(
    () => _dio.post<void>(
      '/support/tickets/${Uri.encodeComponent(ticketId)}/messages',
      data: {'message': message},
    ),
  );

  static SupportTicketSummary _summary(Map<String, dynamic> j) =>
      SupportTicketSummary(
        id: j.str('id'),
        category: _category(j.strOrNull('category')),
        subject: j.str('subject'),
        status: _status(j.strOrNull('status')),
        messageCount: j.integer('messageCount'),
        createdAt: j.date('createdAtUtc'),
        lastActivityAt: j.date('lastActivityAtUtc'),
      );

  static SupportTicketThread _thread(Map<String, dynamic> j) =>
      SupportTicketThread(
        id: j.str('id'),
        category: _category(j.strOrNull('category')),
        subject: j.str('subject'),
        status: _status(j.strOrNull('status')),
        createdAt: j.date('createdAtUtc'),
        lastActivityAt: j.date('lastActivityAtUtc'),
        messages: j.list(
          'messages',
          (m) => SupportTicketMessage(
            id: m.str('id'),
            author: m.strOrNull('authorKind') == 'Admin'
                ? TicketAuthor.admin
                : TicketAuthor.user,
            body: m.str('body'),
            createdAt: m.date('createdAtUtc'),
          ),
        ),
      );

  static String _categoryName(TicketCategory category) => switch (category) {
    TicketCategory.account => 'Account',
    TicketCategory.payment => 'Payment',
    TicketCategory.data => 'Data',
    TicketCategory.other => 'Other',
  };

  /// `null` for a category this app version does not know.
  static TicketCategory? _category(String? value) => switch (value) {
    'Account' => TicketCategory.account,
    'Payment' => TicketCategory.payment,
    'Data' => TicketCategory.data,
    'Other' => TicketCategory.other,
    _ => null,
  };

  static TicketStatus _status(String? value) => switch (value) {
    'InProgress' => TicketStatus.inProgress,
    'Resolved' => TicketStatus.resolved,
    'Closed' => TicketStatus.closed,
    _ => TicketStatus.open,
  };
}
