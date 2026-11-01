import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../support/presentation/ticket_text.dart';
import '../domain/admin_support.dart';
import 'admin_tickets_cubit.dart';

/// The support queue: tickets newest activity first, filtered by status
/// (opening on those still waiting for an answer).
class AdminTicketsPage extends StatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  State<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends State<AdminTicketsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminTicketsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(AdminTicket ticket) async {
    final cubit = context.read<AdminTicketsCubit>();
    final changed = await context.push<bool>(AppRoutes.adminTicket(ticket.id));
    // A reply or status change moves the ticket in (or out of) this list.
    if (changed ?? false) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminTicketsTitle),
      body: Column(
        children: [
          BlocBuilder<AdminTicketsCubit, AdminTicketsState>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.fromLTRB(
                MbSpacing.s4,
                MbSpacing.s3,
                MbSpacing.s4,
                MbSpacing.s2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: MbSpacing.s2,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.filterAll),
                      selected: state.filter == null,
                      onSelected: (_) => cubit.setFilter(null),
                    ),
                    for (final s in settableStatuses)
                      ChoiceChip(
                        label: Text(ticketStatusLabel(context, s)),
                        selected: state.filter == s,
                        onSelected: (_) => cubit.setFilter(s),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminTicketsCubit, AdminTicketsState>(
              builder: (context, state) {
                if (state.tickets.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminSupportEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount:
                        state.tickets.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.tickets.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _TicketRow(
                            ticket: state.tickets[i],
                            onTap: () => _open(state.tickets[i]),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});

  final AdminTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: t.title.copyWith(color: c.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: MbSpacing.s2),
                MbBadge(
                  label: ticketStatusLabel(context, ticket.status),
                  tone: ticketStatusTone(ticket.status),
                ),
              ],
            ),
            const SizedBox(height: MbSpacing.s1),
            Text(
              '${ticket.userPhone} · '
              '${ticketCategoryLabel(context, ticket.category)} · '
              '${context.timestamp(ticket.lastActivityAt)}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
