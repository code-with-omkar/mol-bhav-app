import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_price.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../domain/billing.dart';
import '../cubit/subscription_cubit.dart';
import 'plans_page.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionCubit>();
    return Scaffold(
      appBar: MbAppBar(title: context.l10n.mySubscription),
      body: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, state) => switch (state) {
          SubscriptionLoaded(:final subscription) => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Content(subscription: subscription),
          ),
          SubscriptionError(:final failure) => MbErrorView(
            failure: failure,
            onRetry: cubit.load,
          ),
          _ => const MbLoadingView(),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.subscription});

  final Subscription? subscription;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final s = subscription;
    final active = s != null && s.isActive;
    final date = s == null
        ? ''
        : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(s.expiresAt);

    final (label, tone) = switch (s?.status) {
      null => (l10n.subscriptionFree, MbBadgeTone.neutral),
      SubscriptionStatus.active => (
        l10n.subscriptionActive(date),
        MbBadgeTone.pro,
      ),
      SubscriptionStatus.expired => (
        l10n.subscriptionExpired,
        MbBadgeTone.neutral,
      ),
      SubscriptionStatus.cancelled => (
        l10n.subscriptionCancelled,
        MbBadgeTone.neutral,
      ),
      SubscriptionStatus.pendingPayment => (
        l10n.subscriptionPending,
        MbBadgeTone.opportunity,
      ),
    };

    return ListView(
      padding: MbSpacing.screenPadding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        MbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s?.planName ?? l10n.subscriptionFree,
                style: context.mbText.h2.copyWith(color: c.ink),
              ),
              const SizedBox(height: MbSpacing.s2),
              MbBadge(label: label, tone: tone),
              const SizedBox(height: MbSpacing.s4),
              for (final feature in proFeatures(l10n))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: MbSpacing.s1),
                  child: Row(
                    children: [
                      MbIcon(
                        active ? MbIcons.check : MbIcons.lock,
                        size: 18,
                        color: active ? c.primaryText : c.inkMuted,
                      ),
                      const SizedBox(width: MbSpacing.s2),
                      Expanded(
                        child: Text(
                          feature,
                          style: context.mbText.body.copyWith(color: c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MbSpacing.s6),
        MbButton(
          label: active ? l10n.renewPro : l10n.upgradeToPro,
          block: true,
          onPressed: () => context.push(AppRoutes.billingPlans),
        ),
        if (active) ...[
          const SizedBox(height: MbSpacing.s3),
          MbButton(
            label: l10n.cancelSubscription,
            variant: MbButtonVariant.ghost,
            block: true,
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<SubscriptionCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelSubscription),
        content: Text(l10n.cancelSubscriptionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.keepSubscription),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.cancelSubscription),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await cubit.cancelSubscription();
    if (result case Err(:final failure) when context.mounted) {
      showFailureSnackBar(context, failure);
    }
  }
}
