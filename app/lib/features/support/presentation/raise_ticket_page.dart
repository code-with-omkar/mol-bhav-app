import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_chip_group.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/support.dart';
import 'support_cubits.dart';
import 'ticket_text.dart';

/// Category, subject and message. On success the new ticket's thread replaces
/// this screen, so the user lands where the answer will arrive.
class RaiseTicketPage extends StatelessWidget {
  const RaiseTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RaiseTicketCubit>();
    return BlocConsumer<RaiseTicketCubit, RaiseTicketState>(
      listenWhen: (p, n) => p.submitStatus != n.submitStatus,
      listener: (context, state) {
        final createdId = state.createdId;
        if (state.submitStatus == SubmitStatus.success && createdId != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.ticketRaised)));
          context.pushReplacement(AppRoutes.supportTicket(createdId));
        } else if (state.submitStatus == SubmitStatus.failure) {
          showFailureSnackBar(context, state.submitFailure!);
        }
      },
      builder: (context, state) {
        final c = context.mbColors;
        final t = context.mbText;
        const gap = SizedBox(height: MbSpacing.s4);

        return Scaffold(
          appBar: MbAppBar(title: l10n.raiseTicket),
          body: ListView(
            padding: MbSpacing.screenPadding,
            children: [
              Text(
                l10n.ticketCategoryLabel,
                style: t.fieldLabel.copyWith(color: c.ink),
              ),
              const SizedBox(height: MbSpacing.s2),
              MbChipGroup<TicketCategory>.single(
                semanticLabel: l10n.ticketCategoryLabel,
                value: state.category,
                onChanged: cubit.selectCategory,
                options: [
                  for (final category in TicketCategory.values)
                    MbChipOption(
                      value: category,
                      label: ticketCategoryLabel(context, category),
                    ),
                ],
              ),
              gap,
              MbTextField(
                label: l10n.ticketSubjectLabel,
                hint: l10n.ticketSubjectHint,
                textInputAction: TextInputAction.next,
                onChanged: cubit.subjectChanged,
                helper: l10n.ticketSubjectHelper(
                  RaiseTicketState.subjectMinLength,
                ),
              ),
              gap,
              MbTextField(
                label: l10n.ticketMessageLabel,
                hint: l10n.ticketMessageHint,
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 10,
                onChanged: cubit.messageChanged,
              ),
            ],
          ),
          bottomNavigationBar: MbFooter(
            child: MbButton(
              label: l10n.submitTicket,
              size: MbButtonSize.lg,
              block: true,
              isLoading: state.submitStatus == SubmitStatus.submitting,
              onPressed: state.canSubmit ? cubit.submit : null,
            ),
          ),
        );
      },
    );
  }
}
