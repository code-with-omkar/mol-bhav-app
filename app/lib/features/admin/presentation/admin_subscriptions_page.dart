import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_subscriptions.dart';
import 'admin_subscriptions_cubit.dart';

/// "Active", "Awaiting payment", … in the app's language.
String subscriptionStateLabel(AppLocalizations l10n, SubscriptionState s) =>
    switch (s) {
      SubscriptionState.active => l10n.campaignStatusActive,
      SubscriptionState.pendingPayment => l10n.adminSubPending,
      SubscriptionState.cancelled => l10n.adminSubCancelled,
      SubscriptionState.expired => l10n.adminSubExpired,
    };

/// Who has a plan, newest first, filtered by state (opening on the active
/// ones). Tap a row to open the user; an active subscription can be ended
/// early after a confirmation.
class AdminSubscriptionsPage extends StatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminSubscriptionsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _end(AdminSubscription subscription) async {
    final l10n = context.l10n;
    final cubit = context.read<AdminSubscriptionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.adminSubEndTitle),
        content: Text(l10n.adminSubEndBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.adminSubEndConfirm),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    final failure = await cubit.end(subscription);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? l10n.adminSubEnded
              : failureMessage(context, failure),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminSubscriptionsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminSubsTitle),
      body: Column(
        children: [
          BlocBuilder<AdminSubscriptionsCubit, AdminSubscriptionsState>(
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
                    for (final s in SubscriptionState.values)
                      ChoiceChip(
                        label: Text(subscriptionStateLabel(l10n, s)),
                        selected: state.filter == s,
                        onSelected: (_) => cubit.setFilter(s),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                BlocBuilder<AdminSubscriptionsCubit, AdminSubscriptionsState>(
                  builder: (context, state) {
                    if (state.subscriptions.isEmpty) {
                      return switch (state.status) {
                        LoadStatus.failure => MbErrorView(
                          failure: state.failure!,
                          onRetry: cubit.load,
                        ),
                        LoadStatus.ready => MbEmptyView(
                          message: l10n.adminSubsEmpty,
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
                            state.subscriptions.length +
                            (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: MbSpacing.s2),
                        itemBuilder: (context, i) =>
                            i >= state.subscriptions.length
                            ? const Padding(
                                padding: EdgeInsets.all(MbSpacing.s3),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _SubscriptionCard(
                                subscription: state.subscriptions[i],
                                onOpen: () => context.push(
                                  AppRoutes.adminUser(
                                    state.subscriptions[i].userId,
                                  ),
                                ),
                                onEnd: () => _end(state.subscriptions[i]),
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

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onOpen,
    required this.onEnd,
  });

  final AdminSubscription subscription;
  final VoidCallback onOpen;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final s = subscription;

    // The second line says what matters for that state.
    final detail = switch (s.status) {
      SubscriptionState.active => [
        l10n.adminSubEnds(day.format(s.expiresAt.toLocal())),
        if (s.isAutoRenew) l10n.adminSubAutoRenew,
      ].join(' · '),
      SubscriptionState.pendingPayment => l10n.adminSubWaiting,
      SubscriptionState.cancelled => l10n.adminSubCancelledOn(
        day.format((s.cancelledAt ?? s.expiresAt).toLocal()),
      ),
      SubscriptionState.expired => l10n.adminSubEndedOn(
        day.format(s.expiresAt.toLocal()),
      ),
    };

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.userLabel ?? l10n.adminSubUnknownUser,
                    style: t.title.copyWith(color: c.ink),
                  ),
                ),
                const SizedBox(width: MbSpacing.s2),
                MbBadge(
                  label: subscriptionStateLabel(l10n, s.status),
                  tone: s.status == SubscriptionState.active
                      ? MbBadgeTone.best
                      : MbBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: MbSpacing.s1),
            Text(
              '${s.planCode} · '
              '${l10n.adminSubStarted(day.format(s.startedAt.toLocal()))}',
              style: t.body.copyWith(color: c.ink),
            ),
            Text(detail, style: t.caption.copyWith(color: c.inkMuted)),
            if (s.canEnd)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onEnd,
                  child: Text(l10n.adminSubEndNow),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
