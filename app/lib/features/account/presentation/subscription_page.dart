import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_cards.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/account.dart';
import 'account_cubits.dart';

/// Free vs Pro. The upgrade action is not wired: the payment flow is not
/// defined yet.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.choosePlanTitle),
      body: BlocBuilder<SubscriptionCubit, DataState<List<SubscriptionPlan>>>(
        builder: (context, state) {
          final cubit = context.read<SubscriptionCubit>();
          return switch (state.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Plans(plans: state.data!),
            _ => const MbLoadingView(),
          };
        },
      ),
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.plans});

  final List<SubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        for (final plan in plans) ...[
          MbPlanCard(
            name: plan.name,
            price: formatInr(plan.price),
            period: switch (plan.period) {
              BillingPeriod.month => l10n.perMonth,
              BillingPeriod.year => l10n.perYear,
              null => null,
            },
            features: plan.features,
            featured: plan.isFeatured,
            currentLabel: plan.isCurrent ? l10n.currentPlan : null,
            actionLabel: plan.isCurrent ? null : l10n.upgradeTo(plan.name),
            onAction: null,
          ),
          const SizedBox(height: MbSpacing.s4),
        ],
        Text(
          l10n.cancelAnytime,
          textAlign: TextAlign.center,
          style: context.mbText.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}
