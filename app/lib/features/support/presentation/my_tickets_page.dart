import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/support.dart';
import 'support_cubits.dart';
import 'ticket_text.dart';

/// The user's tickets, most recently active first.
class MyTicketsPage extends StatelessWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.myTickets),
      body: BlocBuilder<MyTicketsCubit, DataState<List<SupportTicketSummary>>>(
        builder: (context, state) {
          final cubit = context.read<MyTicketsCubit>();
          final tickets = state.data;
          if (tickets == null) {
            return state.status == LoadStatus.failure
                ? MbErrorView(failure: state.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                if (tickets.isEmpty)
                  MbEmptyView(message: l10n.ticketsEmpty)
                else
                  MbGroup(
                    children: [
                      for (final ticket in tickets) _TicketRow(ticket: ticket),
                    ],
                  ),
                const SizedBox(height: MbSpacing.s6),
                MbButton(
                  label: l10n.raiseTicket,
                  icon: MbIcons.edit,
                  block: true,
                  onPressed: () => context.push(AppRoutes.raiseTicket),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final SupportTicketSummary ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return MbListItem(
      icon: MbIcons.help,
      iconTone: ticket.status == TicketStatus.closed
          ? MbTone.neutral
          : MbTone.green,
      title: ticket.subject,
      subtitle:
          '${ticketCategoryLabel(context, ticket.category)} · '
          '${l10n.ticketUpdatedAt(formatDateTime(ticket.lastActivityAt, locale))}',
      trailing: MbBadge(
        label: ticketStatusLabel(context, ticket.status),
        tone: ticketStatusTone(ticket.status),
      ),
      onTap: () => context.push(AppRoutes.supportTicket(ticket.id)),
    );
  }
}
