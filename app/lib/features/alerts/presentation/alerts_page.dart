import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_cards.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/alerts.dart';
import 'alerts_cubits.dart';

/// Price signals, spikes and opportunities, newest first.
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.alertsTitle,
        actions: [
          // Alert settings have no screen in the design yet.
          MbAppBarAction(
            icon: MbIcons.settings,
            label: l10n.alertSettings,
            onPressed: null,
          ),
        ],
      ),
      body: BlocBuilder<AlertsCubit, AlertsState>(
        builder: (context, state) {
          final cubit = context.read<AlertsCubit>();
          final alerts = state.data.data;
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                MbSegmentedTabs<AlertFilter>(
                  value: state.filter,
                  onChanged: cubit.selectFilter,
                  options: [
                    MbTabOption(value: AlertFilter.all, label: l10n.filterAll),
                    MbTabOption(
                      value: AlertFilter.signals,
                      label: l10n.filterPriceSignals,
                    ),
                    MbTabOption(
                      value: AlertFilter.opportunities,
                      label: l10n.filterOpportunities,
                    ),
                  ],
                ),
                const SizedBox(height: MbSpacing.s3),
                if (state.data.status == LoadStatus.failure)
                  MbErrorView(failure: state.data.failure!, onRetry: cubit.load)
                else if (alerts == null)
                  const SizedBox(height: 240, child: MbLoadingView())
                else if (alerts.isEmpty)
                  MbEmptyView(message: l10n.alertsEmpty)
                else
                  for (final alert in alerts) ...[
                    _AlertTile(alert: alert),
                    const SizedBox(height: MbSpacing.s3),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final opportunityId = alert.opportunityId;
    return MbAlertCard(
      variant: switch (alert.kind) {
        AlertKind.signal => MbAlertVariant.signal,
        AlertKind.spike => MbAlertVariant.spike,
        AlertKind.opportunity => MbAlertVariant.opportunity,
      },
      kind: switch (alert.kind) {
        AlertKind.signal => l10n.kindSignal,
        AlertKind.spike => l10n.kindSpike,
        AlertKind.opportunity => l10n.kindOpportunity,
      },
      unread: alert.isUnread,
      time: context.timestamp(alert.createdAt),
      title: alert.title,
      details: alert.details,
      channel: switch (alert.channel) {
        AlertChannel.whatsapp => l10n.sentOnWhatsApp,
        AlertChannel.push => l10n.sentAsPush,
        null => null,
      },
      actionLabel: opportunityId == null
          ? null
          : alert.kind == AlertKind.opportunity
          ? l10n.viewDetails
          : l10n.viewOpportunity,
      onAction: opportunityId == null
          ? null
          : () => context.push(AppRoutes.opportunity(opportunityId)),
    );
  }
}
