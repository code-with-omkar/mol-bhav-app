import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_cards.dart';
import '../../../../shared/widgets/mb_panels.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../domain/billing.dart';
import '../cubit/plans_cubit.dart';
import '../widgets/subscription_guard.dart';

/// Free vs Pro, with a Monthly / Yearly switch. Pro users see their plan
/// marked current and can renew from here (the API allows it in the last
/// week of a period and answers 409 before that).
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MbAppBar(title: context.l10n.choosePlanTitle),
      body: BlocBuilder<PlansCubit, PlansState>(
        builder: (context, state) => switch (state) {
          PlansLoaded() => _Plans(state: state),
          PlansError(:final failure) => MbErrorView(
            failure: failure,
            onRetry: context.read<PlansCubit>().load,
          ),
          _ => const MbLoadingView(),
        },
      ),
    );
  }
}

/// Only what the API actually enforces belongs here. Price-history export is
/// the single `pro-subscriber` gate today; alerts, the cost estimator and
/// mandi comparison are free and listed on the Free card instead.
List<String> freeFeatures(AppLocalizations l10n) => [
  l10n.freeFeatureBasicPrices,
  l10n.freeFeatureWatchlist,
  l10n.proFeatureAlerts,
  l10n.proFeatureProcurement,
  l10n.proFeatureComparison,
];

List<String> proFeatures(AppLocalizations l10n) => [
  l10n.proFeatureEverythingInFree,
  l10n.proFeatureReports,
];

class _Plans extends StatelessWidget {
  const _Plans({required this.state});

  final PlansLoaded state;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final cubit = context.read<PlansCubit>();
    final isPro = context.isProSubscriber;
    final saving = state.yearlySavingPercent;

    final free = MbPlanCard(
      name: l10n.subscriptionFree,
      price: formatPaise(0),
      features: freeFeatures(l10n),
      currentLabel: isPro ? null : l10n.currentPlan,
    );
    final paid = [
      for (final plan in state.visiblePlans)
        MbPlanCard(
          name: plan.name,
          price: formatPaise(plan.pricePaise),
          period: plan.cycle == BillingCycle.yearly
              ? l10n.perYear
              : l10n.perMonth,
          features: proFeatures(l10n),
          featured: true,
          currentLabel: isPro ? l10n.currentPlan : null,
          actionLabel: isPro ? l10n.renewPro : l10n.upgradeToPro,
          onAction: () => context.push(AppRoutes.checkoutFor(plan.code)),
        ),
    ];

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbSegmentedTabs<BillingCycle>(
          stretch: true,
          value: state.cycle,
          onChanged: (cycle) {
            if (cycle != state.cycle) cubit.toggleBillingCycle();
          },
          options: [
            MbTabOption(
              value: BillingCycle.monthly,
              label: l10n.monthlyBilling,
            ),
            MbTabOption(
              value: BillingCycle.yearly,
              label: saving == null
                  ? l10n.yearlyBillingPlain
                  : l10n.yearlyBilling(saving),
            ),
          ],
        ),
        const SizedBox(height: MbSpacing.s4),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [free, ...paid];
            if (constraints.maxWidth >= 600) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: MbSpacing.s4),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: MbSpacing.s4),
                  cards[i],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(
          l10n.cancelAnytime,
          textAlign: TextAlign.center,
          style: context.mbText.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}
