import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_trend_chart.dart';
import '../domain/admin_ads.dart';
import 'admin_ads_cubit.dart' show adsRanges;
import 'admin_campaign_cubit.dart';
import 'admin_stat_card.dart';

String _n(num value) => NumberFormat.decimalPattern().format(value);

String _rate(num percent) => '${NumberFormat('0.0').format(percent)}%';

/// One campaign's impressions, clicks and click rate per day. [campaign] is
/// the row tapped on the Ads tab; without it (a direct link) the page shows
/// the figures alone.
class AdminCampaignPage extends StatelessWidget {
  const AdminCampaignPage({super.key, required this.campaignId, this.campaign});

  final String campaignId;
  final CampaignPerformance? campaign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminCampaignCubit>();
    return Scaffold(
      appBar: MbAppBar(title: campaign?.name ?? l10n.adminCampaignTitle),
      body: BlocBuilder<AdminCampaignCubit, AdminCampaignState>(
        builder: (context, state) {
          final rows = state.data.data;
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
                child: rows == null
                    ? (state.data.status == LoadStatus.failure
                          ? MbErrorView(
                              failure: state.data.failure!,
                              onRetry: cubit.reload,
                            )
                          : const MbLoadingView())
                    : RefreshIndicator(
                        onRefresh: cubit.reload,
                        child: _Content(rows: rows, campaign: campaign),
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
  const _Content({required this.rows, required this.campaign});

  final List<AdsDay> rows;
  final CampaignPerformance? campaign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final dayFormat = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    );
    final impressions = rows.fold<int>(0, (sum, d) => sum + d.impressions);
    final clicks = rows.fold<int>(0, (sum, d) => sum + d.clicks);
    final rate = impressions == 0 ? 0.0 : clicks * 100 / impressions;

    List<MbTrendPoint> series(num Function(AdsDay) value) => [
      for (final d in rows)
        MbTrendPoint(label: dayFormat.format(d.day), value: value(d)),
    ];

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        if (campaign != null) ...[
          Text(
            '${campaign!.advertiserName} · ${campaign!.placementLabel}',
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s2),
        ],
        AdminStatCard(
          title: l10n.adminAdsTotalsTitle,
          stats: [
            AdminStat(l10n.adminAdsClicks, _n(clicks)),
            AdminStat(l10n.adminAdsImpressions, _n(impressions)),
            AdminStat(l10n.adminAdsClickRateShort, _rate(rate)),
          ],
        ),
        const SizedBox(height: MbSpacing.s3),
        if (impressions == 0 && clicks == 0)
          Text(
            l10n.adminCampaignNoDelivery,
            style: t.body.copyWith(color: c.inkMuted),
          )
        else if (rows.length >= 2) ...[
          MbTrendChart(
            title: l10n.adminAdsDailyImpressions,
            data: series((d) => d.impressions),
            format: _n,
          ),
          const SizedBox(height: MbSpacing.s3),
          MbTrendChart(
            title: l10n.adminAdsDailyClicks,
            data: series((d) => d.clicks),
            format: _n,
          ),
          const SizedBox(height: MbSpacing.s3),
          MbTrendChart(
            title: l10n.adminAdsDailyClickRate,
            data: series(
              (d) => double.parse(d.clickRatePercent.toStringAsFixed(2)),
            ),
            format: _rate,
          ),
        ],
      ],
    );
  }
}
