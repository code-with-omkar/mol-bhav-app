import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_users.dart';
import 'admin_user_detail_cubit.dart';

/// One user in full, with suspend / reinstate. Leaving the page reports (as
/// the pop result) whether the account's standing changed, so the list can
/// refresh.
class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminUserDetailCubit>();
    return PopScope(
      // Take over the pop so the result can carry "changed".
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(cubit.state.changed);
      },
      child: Scaffold(
        appBar: MbAppBar(
          title: l10n.adminUserDetailTitle,
          onBack: () => context.pop(cubit.state.changed),
        ),
        body: BlocConsumer<AdminUserDetailCubit, AdminUserDetailState>(
          listenWhen: (a, b) => b.actionFailure != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failureMessage(context, state.actionFailure!)),
              ),
            );
            cubit.failureShown();
          },
          builder: (context, state) {
            final detail = state.detail.data;
            if (detail == null) {
              return state.detail.status == LoadStatus.failure
                  ? MbErrorView(
                      failure: state.detail.failure!,
                      onRetry: () => cubit.load(userId),
                    )
                  : const MbLoadingView();
            }
            return _Content(detail: detail, busy: state.busy, userId: userId);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.detail,
    required this.busy,
    required this.userId,
  });

  final AdminUserDetail detail;
  final bool busy;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final user = detail.user;
    final sub = detail.latestSubscription;
    final last = user.lastLoginAt;

    final rows = <(String, String)>[
      (l10n.adminUserPhone, user.phoneNumber),
      if (user.place != null) (l10n.adminUserLocation, user.place!),
      if (user.businessType != null)
        (l10n.adminUserBusiness, user.businessType!),
      if (detail.categories.isNotEmpty)
        (l10n.adminUserCategories, detail.categories.join(', ')),
      (l10n.adminUserJoined, context.timestamp(user.createdAt)),
      (
        l10n.adminUserLastLogin,
        last == null ? l10n.adminUserNever : context.timestamp(last),
      ),
      (
        l10n.adminUserSubscription,
        sub == null
            ? l10n.adminUserSubscriptionNone
            : l10n.adminUserSubscriptionValue(
                sub.planName,
                sub.status,
                context.timestamp(sub.expiresAt),
              ),
      ),
      (
        l10n.adminUserTickets,
        l10n.adminUserTicketsValue(detail.ticketsTotal, detail.ticketsOpen),
      ),
    ];

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.title, style: t.h2.copyWith(color: c.ink)),
              const SizedBox(height: MbSpacing.s2),
              Wrap(
                spacing: MbSpacing.s1,
                children: [
                  MbBadge(
                    label: user.isSuspended
                        ? l10n.adminUsersSuspended
                        : l10n.adminUserActive,
                    tone: user.isSuspended
                        ? MbBadgeTone.opportunity
                        : MbBadgeTone.best,
                  ),
                  MbBadge(
                    label: user.isPro
                        ? l10n.adminUsersPro
                        : l10n.adminUsersFree,
                    tone: user.isPro ? MbBadgeTone.pro : MbBadgeTone.neutral,
                  ),
                  if (user.isAdmin)
                    MbBadge(
                      label: l10n.adminUserAdminBadge,
                      tone: MbBadgeTone.neutral,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbCard(
          child: Column(
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MbSpacing.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          label,
                          style: t.caption.copyWith(color: c.inkMuted),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          value,
                          style: t.body.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // An admin account cannot be suspended (the server refuses too).
        if (!user.isAdmin) ...[
          const SizedBox(height: MbSpacing.s4),
          MbButton(
            label: user.isSuspended
                ? l10n.adminUserReinstateAction
                : l10n.adminUserSuspendAction,
            variant: user.isSuspended
                ? MbButtonVariant.primary
                : MbButtonVariant.secondary,
            block: true,
            isLoading: busy,
            onPressed: busy
                ? null
                : () => user.isSuspended
                      ? context.read<AdminUserDetailCubit>().setSuspended(
                          userId,
                          suspend: false,
                        )
                      : _confirmSuspend(context),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmSuspend(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AdminUserDetailCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.adminUserSuspendTitle),
        content: Text(l10n.adminUserSuspendBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.adminUserSuspendConfirm),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.setSuspended(userId, suspend: true);
  }
}
