import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/admin_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_trend_chart.dart';
import '../domain/admin_ads.dart';
import 'admin_ads_cubit.dart';
import 'admin_stat_card.dart';
import 'ads_change.dart';

String _n(num value) => NumberFormat.decimalPattern().format(value);

String _rate(double percent) => '${NumberFormat('0.0').format(percent)}%';

/// Sponsored-ad delivery for admins: totals, clicks per day and every
/// campaign's impressions, clicks and click rate over the chosen range.
class AdminAdsPage extends StatelessWidget {
  const AdminAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminAdsCubit>();
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.adminAdsTitle,
        showBack: false,
        actions: [
          MbAppBarAction(
            icon: MbIcons.user,
            label: l10n.adminSwitchToUserView,
            onPressed: () => getIt<AdminMode>().switchToUserView(),
          ),
        ],
      ),
      body: BlocBuilder<AdminAdsCubit, AdminAdsState>(
        builder: (context, state) {
          final data = state.data.data;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MbSpacing.s4,
                  MbSpacing.s3,
                  MbSpacing.s4,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: MbSpacing.s2,
                    children: [
                      for (final days in adsRanges)
                        ChoiceChip(
                          label: Text(l10n.adminRangeDays(days)),
                          selected: state.days == days,
                          onSelected: (_) => cubit.setDays(days),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: data == null
                    ? (state.data.status == LoadStatus.failure
                          ? MbErrorView(
                              failure: state.data.failure!,
                              onRetry: cubit.load,
                            )
                          : const MbLoadingView())
                    : RefreshIndicator(
                        onRefresh: cubit.load,
                        child: _Content(overview: data),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final AdsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final locale = Localizations.localeOf(context).toString();
    final dayFormat = DateFormat.MMMd(locale);

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        AdminStatCard(
          title: l10n.adminAdsTotalsTitle,
          stats: [
            AdminStat(
              l10n.adminAdsClicks,
              _n(overview.clicks),
              change: countChange(
                context,
                overview.clicks,
                overview.previous?.clicks,
              ),
            ),
            AdminStat(
              l10n.adminAdsImpressions,
              _n(overview.impressions),
              change: countChange(
                context,
                overview.impressions,
                overview.previous?.impressions,
              ),
            ),
            AdminStat(
              l10n.adminAdsClickRateShort,
              _rate(overview.clickRatePercent),
              change: rateChange(
                context,
                overview.clickRatePercent,
                overview.previous?.clickRatePercent,
              ),
            ),
          ],
          note: overview.previous == null
              ? l10n.adminAdsNote
              : '${l10n.adminAdsNote}\n'
                    '${l10n.adminAdsChangeNote(overview.to.difference(overview.from).inDays + 1)}',
        ),
        if (overview.daily.length >= 2) ...[
          const SizedBox(height: MbSpacing.s3),
          MbTrendChart(
            title: l10n.adminAdsDailyClicks,
            data: [
              for (final d in overview.daily)
                MbTrendPoint(label: dayFormat.format(d.day), value: d.clicks),
            ],
            format: _n,
          ),
        ],
        if (overview.campaigns.isNotEmpty) ...[
          const SizedBox(height: MbSpacing.s4),
          Text(
            l10n.adminAdsPlacementsTitle,
            style: t.title.copyWith(color: c.ink),
          ),
          const SizedBox(height: MbSpacing.s2),
          for (final placement in overview.byPlacement) ...[
            _PlacementCard(
              placement: placement,
              previous: overview.previous?.byPlacement
                  .where((p) => p.placement == placement.placement)
                  .firstOrNull,
              compared: overview.previous != null,
            ),
            const SizedBox(height: MbSpacing.s2),
          ],
        ],
        const SizedBox(height: MbSpacing.s4),
        Text(
          l10n.adminAdsCampaignsTitle,
          style: t.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: MbSpacing.s2),
        if (overview.campaigns.isEmpty)
          Text(
            l10n.adminAdsNoCampaigns,
            style: t.body.copyWith(color: c.inkMuted),
          )
        else
          for (final campaign in overview.campaigns) ...[
            _CampaignCard(
              campaign: campaign,
              previous: overview.previousCampaign(campaign.id),
              compared: overview.previous != null,
            ),
            const SizedBox(height: MbSpacing.s2),
          ],
      ],
    );
  }
}

/// One place in the app (e.g. Home Feed): its campaigns' delivery added up.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.placement,
    required this.previous,
    required this.compared,
  });

  final PlacementPerformance placement;

  /// The placement in the previous range; null if nothing ran there then.
  final PlacementPerformance? previous;
  final bool compared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(placement.label, style: t.title.copyWith(color: c.ink)),
          Text(
            l10n.adminAdsCampaignCount(placement.campaigns),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s3),
          Row(
            children: [
              _Figure(
                l10n.adminAdsClicks,
                _n(placement.clicks),
                change: compared
                    ? countChange(
                        context,
                        placement.clicks,
                        previous?.clicks ?? 0,
                      )
                    : null,
              ),
              _Figure(
                l10n.adminAdsImpressions,
                _n(placement.impressions),
                change: compared
                    ? countChange(
                        context,
                        placement.impressions,
                        previous?.impressions ?? 0,
                      )
                    : null,
              ),
              _Figure(
                l10n.adminAdsClickRateShort,
                _rate(placement.clickRatePercent),
                change: compared
                    ? rateChange(
                        context,
                        placement.clickRatePercent,
                        previous?.clickRatePercent ?? 0,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.previous,
    required this.compared,
  });

  final CampaignPerformance campaign;

  /// The campaign's figures in the previous range; null if it had none then.
  final CampaignPerformance? previous;

  /// Whether a previous range was loaded at all. A campaign missing from it
  /// counts as zero (new), not as "unknown".
  final bool compared;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          context.push(AppRoutes.adminCampaign(campaign.id), extra: campaign),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: t.title.copyWith(color: c.ink),
                  ),
                ),
                MbBadge(
                  label: switch (campaign.status) {
                    CampaignState.draft => l10n.campaignStatusDraft,
                    CampaignState.active => l10n.campaignStatusActive,
                    CampaignState.paused => l10n.campaignStatusPaused,
                    CampaignState.ended => l10n.campaignStatusEnded,
                  },
                  tone: campaign.status == CampaignState.active
                      ? MbBadgeTone.best
                      : MbBadgeTone.neutral,
                ),
              ],
            ),
            Text(
              '${campaign.advertiserName} · ${campaign.placementLabel}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: MbSpacing.s3),
            Row(
              children: [
                _Figure(
                  l10n.adminAdsClicks,
                  _n(campaign.clicks),
                  change: compared
                      ? countChange(
                          context,
                          campaign.clicks,
                          previous?.clicks ?? 0,
                        )
                      : null,
                ),
                _Figure(
                  l10n.adminAdsImpressions,
                  _n(campaign.impressions),
                  change: compared
                      ? countChange(
                          context,
                          campaign.impressions,
                          previous?.impressions ?? 0,
                        )
                      : null,
                ),
                _Figure(
                  l10n.adminAdsClickRateShort,
                  _rate(campaign.clickRatePercent),
                  change: compared
                      ? rateChange(
                          context,
                          campaign.clickRatePercent,
                          previous?.clickRatePercent ?? 0,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {this.change});

  final String label;
  final String value;
  final AdminChange? change;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.title.copyWith(color: c.ink)),
          Text(label, style: t.caption.copyWith(color: c.inkMuted)),
          if (change != null) AdminChangeText(change!),
        ],
      ),
    );
  }
}
