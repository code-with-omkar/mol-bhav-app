import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_icon_button.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../../support/domain/support.dart';
import '../../support/presentation/ticket_text.dart';
import '../domain/admin_support.dart';
import 'admin_ticket_thread_cubit.dart';

/// One ticket for support: the conversation, a reply box and the status
/// controls. Leaving the page reports (as the pop result) whether anything was
/// saved, so the queue can refresh.
class AdminTicketThreadPage extends StatefulWidget {
  const AdminTicketThreadPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<AdminTicketThreadPage> createState() => _AdminTicketThreadPageState();
}

class _AdminTicketThreadPageState extends State<AdminTicketThreadPage> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _chooseStatus(TicketStatus status) async {
    final cubit = context.read<AdminTicketThreadCubit>();
    if (status == TicketStatus.closed) {
      // A closed ticket is final: the API takes no more replies or changes.
      final l10n = context.l10n;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.adminSupportCloseTitle),
          content: Text(l10n.adminSupportCloseBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.adminSupportCloseConfirm),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    await cubit.setStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketThreadCubit>();
    return PopScope(
      // Take over the pop so the result can carry "something changed".
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(cubit.state.changes > 0);
      },
      child: BlocConsumer<AdminTicketThreadCubit, AdminTicketThreadState>(
        listenWhen: (a, b) => b.actionFailure != null || b.replies > a.replies,
        listener: (context, state) {
          if (state.actionFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failureMessage(context, state.actionFailure!)),
              ),
            );
            cubit.failureShown();
          } else {
            _draft.clear();
          }
        },
        builder: (context, state) {
          final thread = state.thread.data;
          return Scaffold(
            appBar: MbAppBar(
              title: thread?.subject ?? l10n.adminSupportTicketTitle,
              onBack: () => context.pop(cubit.state.changes > 0),
            ),
            body: thread == null
                ? (state.thread.status == LoadStatus.failure
                      ? MbErrorView(
                          failure: state.thread.failure!,
                          onRetry: cubit.refresh,
                        )
                      : const MbLoadingView())
                : _Thread(
                    thread: thread,
                    busy: state.busy,
                    onStatus: _chooseStatus,
                  ),
            bottomNavigationBar: thread == null
                ? null
                : _ReplyBox(
                    controller: _draft,
                    thread: thread,
                    busy: state.busy,
                  ),
          );
        },
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.thread,
    required this.busy,
    required this.onStatus,
  });

  final SupportTicketThread thread;
  final bool busy;
  final ValueChanged<TicketStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final cubit = context.read<AdminTicketThreadCubit>();
    final locale = Localizations.localeOf(context).languageCode;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: MbSpacing.screenPadding,
        children: [
          Text(
            ticketCategoryLabel(context, thread.category),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s2),
          Text(l10n.adminSupportStatus, style: t.title.copyWith(color: c.ink)),
          const SizedBox(height: MbSpacing.s2),
          Wrap(
            spacing: MbSpacing.s2,
            children: [
              for (final s in settableStatuses)
                ChoiceChip(
                  label: Text(ticketStatusLabel(context, s)),
                  selected: thread.status == s,
                  // A closed ticket is final.
                  onSelected: busy || !thread.canReply
                      ? null
                      : (_) => onStatus(s),
                ),
            ],
          ),
          const SizedBox(height: MbSpacing.s4),
          for (final message in thread.messages) ...[
            _Bubble(message: message, locale: locale),
            const SizedBox(height: MbSpacing.s3),
          ],
        ],
      ),
    );
  }
}

/// Support's own words on the right in the brand green, the user's on the left
/// on a card (the mirror of what the user sees).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.locale});

  final SupportTicketMessage message;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final mine = message.author == TicketAuthor.admin;

    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MbSpacing.s4,
            vertical: MbSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: mine ? c.surfaceGreen : c.surfaceCard,
            border: Border.all(color: mine ? c.primary : c.borderStrong),
            borderRadius: BorderRadius.circular(MbRadius.lg),
          ),
          child: Text(message.body, style: t.body.copyWith(color: c.ink)),
        ),
        const SizedBox(height: 4),
        Text(
          '${mine ? l10n.ticketAuthorYou : l10n.adminSupportAuthorUser} · '
          '${formatDateTime(message.createdAt, locale)}',
          style: t.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

class _ReplyBox extends StatelessWidget {
  const _ReplyBox({
    required this.controller,
    required this.thread,
    required this.busy,
  });

  final TextEditingController controller;
  final SupportTicketThread thread;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final cubit = context.read<AdminTicketThreadCubit>();

    if (!thread.canReply) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: Row(
            children: [
              MbIcon(MbIcons.lock, size: 16, color: c.inkMuted),
              const SizedBox(width: MbSpacing.s2),
              Expanded(
                child: Text(
                  l10n.adminSupportClosedNotice,
                  style: context.mbText.caption.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MbSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: MbTextField(
                controller: controller,
                hint: l10n.ticketReplyHint,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 4,
                enabled: !busy,
              ),
            ),
            const SizedBox(width: MbSpacing.s2),
            // Send is on only while there is something to send.
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MbIconButton(
                icon: MbIcons.send,
                label: l10n.sendReply,
                onPressed: busy || controller.text.trim().isEmpty
                    ? null
                    : () => cubit.reply(controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
