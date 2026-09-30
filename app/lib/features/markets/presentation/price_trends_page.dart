import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share/deep_link_config.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_trend_chart.dart';
import '../domain/markets_entities.dart';
import '../../watchlist/presentation/watch_star.dart';
import '../../watchlist/presentation/watchlist_cubit.dart';
import 'markets_cubits.dart';
import 'share/price_share.dart';
import 'share/price_share_data.dart';

/// Historical prices for one commodity in one market.
class PriceTrendsPage extends StatelessWidget {
  const PriceTrendsPage({
    super.key,
    required this.commodityId,
    required this.marketId,
  });

  final String commodityId;
  final String marketId;

  /// The newest point in the loaded range — a trend has no single price, so
  /// the shared card is about the latest day it covers.
  PriceShareData? _shareData(BuildContext context) {
    final trend = context.read<PriceTrendsCubit>().state.data.data;
    final latest = trend?.latest;
    if (trend == null || latest == null) return null;
    return PriceShareData(
      productName: trend.commodityName,
      mandiName: trend.marketName,
      minPrice: latest.min,
      maxPrice: latest.max,
      modalPrice: latest.value,
      unitSymbol: trend.unit,
      recordDate: latest.date,
      source: trend.source,
      link: DeepLinkConfig.productLink(commodityId, mandiId: marketId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final watched = context.select<WatchlistCubit, bool>(
      (c) => c.state.itemFor(commodityId) != null,
    );
    // Nothing to share until the range has loaded at least one price.
    final canShare = context.select<PriceTrendsCubit, bool>(
      (c) => c.state.data.data?.latest != null,
    );
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.priceTrendsTitle,
        actions: [
          MbAppBarAction(
            icon: MbIcons.share,
            label: l10n.sharePrice,
            onPressed: !canShare
                ? null
                : () {
                    final data = _shareData(context);
                    if (data != null) sharePriceCard(context, data);
                  },
          ),
          MbAppBarAction(
            icon: MbIcons.watchlist,
            label: watched ? l10n.removeFromWatchlist : l10n.addToWatchlist,
            selected: watched,
            onPressed: () => toggleWatch(context, commodityId),
          ),
          MbAppBarAction(
            icon: MbIcons.alert,
            label: l10n.createAlertAction,
            onPressed: () => context.push(
              AppRoutes.createAlertFor(
                commodityId: commodityId,
                marketId: marketId,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PriceTrendsCubit, PriceTrendsState>(
        builder: (context, state) {
          final cubit = context.read<PriceTrendsCubit>();
          final trend = state.data.data;
          const gap = SizedBox(height: 14);
          return ListView(
            padding: MbSpacing.screenPadding,
            children: [
              MbSegmentedTabs<TrendRange>(
                stretch: true,
                value: state.range,
                onChanged: cubit.selectRange,
                options: [
                  for (final range in TrendRange.values)
                    MbTabOption(value: range, label: range.code),
                ],
              ),
              gap,
              if (state.data.status == LoadStatus.failure)
                MbErrorView(failure: state.data.failure!, onRetry: cubit.retry)
              else if (trend == null)
                const SizedBox(height: 240, child: MbLoadingView())
              else
                ..._content(context, trend, state.data.isLoading),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(BuildContext context, PriceTrend trend, bool busy) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat('MMM d', locale);
    const gap = SizedBox(height: 14);
    return [
      if (busy) const LinearProgressIndicator(minHeight: 2),
      if (trend.points.isEmpty)
        MbEmptyView(message: l10n.trendsEmpty)
      else
        MbTrendChart(
          title: l10n.trendTitle(
            trend.commodityName,
            trend.marketName,
            trend.unit,
          ),
          data: [
            for (final p in trend.points)
              MbTrendPoint(label: dateFormat.format(p.date), value: p.value),
          ],
        ),
      gap,
      MbCard(
        padding: const EdgeInsets.symmetric(
          vertical: MbSpacing.s3,
          horizontal: MbSpacing.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: MbStat(label: l10n.statMin, value: formatInr(trend.min)),
            ),
            Expanded(
              child: MbStat(
                label: l10n.statModal,
                value: formatInr(trend.modal),
              ),
            ),
            Expanded(
              child: MbStat(label: l10n.statMax, value: formatInr(trend.max)),
            ),
          ],
        ),
      ),
      if (trend.related.isNotEmpty) ...[
        gap,
        MbSectionHeader(title: l10n.relatedMarkets),
        gap,
        MbGroup(
          children: [
            for (final m in trend.related)
              MbPriceRow(
                name: m.marketName,
                price: formatInr(m.price),
                unit: m.unit,
                percent: m.percent,
                onTap: () => context.pushReplacement(
                  AppRoutes.trendsFor(commodityId, m.marketId),
                ),
              ),
          ],
        ),
      ],
    ];
  }
}
