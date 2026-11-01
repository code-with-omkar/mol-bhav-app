import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_support_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_support.dart';
import 'package:mol_bhav/features/admin/presentation/admin_ticket_thread_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_ticket_thread_page.dart';
import 'package:mol_bhav/features/admin/presentation/admin_tickets_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_tickets_page.dart';
import 'package:mol_bhav/features/support/domain/support.dart';
import 'package:mol_bhav/shared/widgets/mb_icon_button.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AdminSupportRepository {}

AdminTicket _ticket(int n, {TicketStatus status = TicketStatus.open}) =>
    AdminTicket(
      id: 't$n',
      userPhone: '+91 98•••••21$n',
      category: TicketCategory.payment,
      subject: 'Payment problem $n',
      status: status,
      messageCount: 2,
      lastActivityAt: DateTime(2026, 11, 1, 10, n),
    );

SupportTicketThread _thread({TicketStatus status = TicketStatus.open}) =>
    SupportTicketThread(
      id: 't1',
      category: TicketCategory.payment,
      subject: 'Payment problem 1',
      status: status,
      createdAt: DateTime(2026, 11, 1, 9),
      lastActivityAt: DateTime(2026, 11, 1, 10),
      messages: [
        SupportTicketMessage(
          id: 'm1',
          author: TicketAuthor.user,
          body: 'My payment went through twice.',
          createdAt: DateTime(2026, 11, 1, 9),
        ),
        SupportTicketMessage(
          id: 'm2',
          author: TicketAuthor.admin,
          body: 'Looking into it now.',
          createdAt: DateTime(2026, 11, 1, 10),
        ),
      ],
    );

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(TicketStatus.open));

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.getTickets(
        status: any(named: 'status'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok([_ticket(1), _ticket(2)]));
    when(() => repository.getTicket(any()))
        .thenAnswer((_) async => Ok(_thread()));
    when(() => repository.reply(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.setStatus(any(), any()))
        .thenAnswer((_) async => const Ok(null));
  });

  test('an API row is read with its masked phone and status', () {
    final ticket = AdminSupportRepositoryImpl.parseTicket({
      'id': 't9',
      'userId': 'u1',
      'userPhoneNumberMasked': '+91 98•••••210',
      'category': 'Payment',
      'subject': 'Charged twice',
      'status': 'InProgress',
      'messageCount': 3,
      'createdAtUtc': '2026-11-01T04:00:00+00:00',
      'lastActivityAtUtc': '2026-11-01T05:00:00+00:00',
    });

    expect(ticket.userPhone, '+91 98•••••210');
    expect(ticket.category, TicketCategory.payment);
    expect(ticket.status, TicketStatus.inProgress);
    expect(ticket.messageCount, 3);
  });

  group('AdminTicketsCubit', () {
    late AdminTicketsCubit cubit;

    setUp(() => cubit = AdminTicketsCubit(repository));
    tearDown(() => cubit.close());

    test('opens on tickets still waiting for an answer', () async {
      await cubit.load();

      expect(cubit.state.filter, TicketStatus.open);
      verify(
        () => repository.getTickets(
          status: TicketStatus.open,
          page: 1,
          pageSize: AdminTicketsCubit.pageSize,
        ),
      ).called(1);
      expect(cubit.state.tickets, hasLength(2));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a filter reloads, and All asks for every status', () async {
      await cubit.load();

      await cubit.setFilter(null);

      expect(cubit.state.filter, isNull);
      verify(
        () => repository.getTickets(
          status: null,
          page: 1,
          pageSize: AdminTicketsCubit.pageSize,
        ),
      ).called(1);
    });

    test('the filter already chosen does nothing', () async {
      await cubit.load();

      await cubit.setFilter(TicketStatus.open);

      verify(
        () => repository.getTickets(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).called(1);
    });

    test('a full page offers more, added to the end', () async {
      final full = [
        for (var i = 0; i < AdminTicketsCubit.pageSize; i++) _ticket(i),
      ];
      when(
        () => repository.getTickets(
          status: TicketStatus.open,
          page: 1,
          pageSize: AdminTicketsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok(full));
      when(
        () => repository.getTickets(
          status: TicketStatus.open,
          page: 2,
          pageSize: AdminTicketsCubit.pageSize,
        ),
      ).thenAnswer((_) async => Ok([_ticket(99)]));
      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();

      expect(cubit.state.tickets, hasLength(AdminTicketsCubit.pageSize + 1));
      expect(cubit.state.hasMore, isFalse);
    });

    test('a failed first load is a failure', () async {
      when(
        () => repository.getTickets(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });
  });

  group('AdminTicketThreadCubit', () {
    late AdminTicketThreadCubit cubit;

    setUp(() => cubit = AdminTicketThreadCubit(repository));
    tearDown(() => cubit.close());

    test('a reply is sent trimmed, then the conversation is reread', () async {
      await cubit.load('t1');

      await cubit.reply('  On it.  ');

      verify(() => repository.reply('t1', 'On it.')).called(1);
      verify(() => repository.getTicket('t1')).called(2);
      expect(cubit.state.changes, 1);
      expect(cubit.state.replies, 1);
    });

    test('an empty reply is not sent', () async {
      await cubit.load('t1');

      await cubit.reply('   ');

      verifyNever(() => repository.reply(any(), any()));
    });

    test('a status change is saved and counted, not as a reply', () async {
      await cubit.load('t1');

      await cubit.setStatus(TicketStatus.resolved);

      verify(() => repository.setStatus('t1', TicketStatus.resolved)).called(1);
      expect(cubit.state.changes, 1);
      expect(cubit.state.replies, 0);
    });

    test('choosing the status it already has does nothing', () async {
      await cubit.load('t1');

      await cubit.setStatus(TicketStatus.open);

      verifyNever(() => repository.setStatus(any(), any()));
    });

    test('a refusal is kept to be shown once and counts for nothing', () async {
      await cubit.load('t1');
      when(() => repository.reply(any(), any())).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'The ticket is closed.')),
      );

      await cubit.reply('Hello');

      expect(cubit.state.changes, 0);
      expect(cubit.state.actionFailure, isA<ServerFailure>());
      cubit.failureShown();
      expect(cubit.state.actionFailure, isNull);
    });
  });

  group('AdminTicketsPage', () {
    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminTicketsCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminTicketsPage()),
      );
    }

    testWidgets('lists tickets with owner, category and status', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Payment problem 1'), findsOneWidget);
      expect(find.textContaining('+91 98•••••211'), findsOneWidget);
      expect(find.textContaining('Payment'), findsWidgets);
      // Chips: All + the four statuses, with Open selected to start.
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('picking a status chip loads that status', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Resolved'));
      await tester.pump();

      verify(
        () => repository.getTickets(
          status: TicketStatus.resolved,
          page: 1,
          pageSize: AdminTicketsCubit.pageSize,
        ),
      ).called(1);
    });

    testWidgets('an empty queue says so', (tester) async {
      when(
        () => repository.getTickets(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Ok([]));

      await pump(tester);

      expect(find.text('No tickets here.'), findsOneWidget);
    });
  });

  group('AdminTicketThreadPage', () {
    Future<AdminTicketThreadCubit> pump(WidgetTester tester) async {
      final cubit = AdminTicketThreadCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('t1');
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const AdminTicketThreadPage(ticketId: 't1'),
        ),
      );
      return cubit;
    }

    testWidgets('shows the conversation with who wrote what', (tester) async {
      await pump(tester);

      expect(find.text('My payment went through twice.'), findsOneWidget);
      expect(find.text('Looking into it now.'), findsOneWidget);
      expect(find.textContaining('User ·'), findsOneWidget);
      expect(find.textContaining('You ·'), findsOneWidget);
    });

    testWidgets('typing a reply enables send, and sending posts it', (
      tester,
    ) async {
      await pump(tester);
      expect(
        tester.widget<MbIconButton>(find.byType(MbIconButton).last).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), 'Refund is on its way.');
      await tester.pump();
      await tester.tap(find.byType(MbIconButton).last);
      await tester.pumpAndSettle();

      verify(() => repository.reply('t1', 'Refund is on its way.')).called(1);
      // The draft is cleared once it has been sent.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('choosing a status saves it', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();

      verify(() => repository.setStatus('t1', TicketStatus.resolved)).called(1);
    });

    testWidgets('closing a ticket asks first, and Cancel keeps it', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();
      expect(find.text('Close this ticket?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.setStatus(any(), any()));
    });

    testWidgets('confirming the close saves it', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close ticket'));
      await tester.pumpAndSettle();

      verify(() => repository.setStatus('t1', TicketStatus.closed)).called(1);
    });

    testWidgets('a closed ticket has no reply box and says why', (
      tester,
    ) async {
      when(() => repository.getTicket(any()))
          .thenAnswer((_) async => Ok(_thread(status: TicketStatus.closed)));

      await pump(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('This ticket is closed'), findsOneWidget);
    });

    testWidgets('a failed load shows an error', (tester) async {
      when(() => repository.getTicket(any()))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });
}
