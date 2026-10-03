import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_icon_button.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/support.dart';
import 'support_cubits.dart';
import 'ticket_text.dart';

/// The conversation, with the reply box disabled once the ticket is closed.
class TicketThreadPage extends StatefulWidget {
  const TicketThreadPage({super.key});

  @override
  State<TicketThreadPage> createState() => _TicketThreadPageState();
}

class _TicketThreadPageState extends State<TicketThreadPage> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TicketThreadCubit>();

    return BlocConsumer<TicketThreadCubit, TicketThreadState>(
      listenWhen: (p, n) => p.submitStatus != n.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == SubmitStatus.success) {
          _draft.clear();
        } else if (state.submitStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.submitFailure!);
        }
      },
      builder: (context, state) {
        final thread = state.thread.data;
        return Scaffold(
          appBar: MbAppBar(title: thread?.subject ?? l10n.ticketTitle),
          body: switch (state.thread.status) {
            _ when thread != null => _Thread(thread: thread, state: state),
            LoadStatus.failure => MbErrorView(
              failure: state.thread.failure!,
              onRetry: cubit.refresh,
            ),
            _ => const MbLoadingView(),
          },
          bottomNavigationBar: thread == null
              ? null
              : _ReplyBox(controller: _draft, thread: thread, state: state),
        );
      },
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({required this.thread, required this.state});

  final SupportTicketThread thread;
  final TicketThreadState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketThreadCubit>();
    final locale = Localizations.localeOf(context).languageCode;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: MbSpacing.screenPadding,
        children: [
          Row(
            children: [
              MbBadge(
                label: ticketStatusLabel(context, thread.status),
                tone: ticketStatusTone(thread.status),
              ),
              const SizedBox(width: MbSpacing.s2),
              Expanded(
                child: Text(
                  ticketCategoryLabel(context, thread.category),
                  style: context.mbText.caption.copyWith(
                    color: context.mbColors.inkMuted,
                  ),
                ),
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

/// The user's own words on the right in the brand green, support's on the left
/// on a card — the side and the colour both carry it, so neither alone has to.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.locale});

  final SupportTicketMessage message;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final mine = message.author == TicketAuthor.user;
    final l10n = context.l10n;

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
          '${mine ? l10n.ticketAuthorYou : l10n.ticketAuthorSupport} · '
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
    required this.state,
  });

  final TextEditingController controller;
  final SupportTicketThread thread;
  final TicketThreadState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final cubit = context.read<TicketThreadCubit>();

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
                  l10n.ticketClosedNotice,
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
                onChanged: cubit.draftChanged,
              ),
            ),
            const SizedBox(width: MbSpacing.s2),
            MbIconButton(
              icon: MbIcons.send,
              label: l10n.sendReply,
              onPressed: state.canSend ? cubit.send : null,
            ),
          ],
        ),
      ),
    );
  }
}
