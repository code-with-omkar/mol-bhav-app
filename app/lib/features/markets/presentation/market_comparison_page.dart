import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/share/deep_link_config.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_chip_group.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/markets_entities.dart';
import '../../promotions/domain/promotions.dart';
import '../../promotions/presentation/ad_slot.dart';
import '../../watchlist/presentation/watch_star.dart';
import '../../watchlist/presentation/watchlist_cubit.dart';
import 'markets_cubits.dart';
import 'share/price_share.dart';
import 'share/price_share_data.dart';

/// Mandi / supplier comparison matrix with the best market called out.
class MarketComparisonPage extends StatelessWidget {
  const MarketComparisonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final commodityId = context.select<MarketComparisonCubit, String?>(
      (c) => c.state.commodityId,
    );
    final watched = context.select<WatchlistCubit, bool>(
      (c) => commodityId != null && c.state.itemFor(commodityId) != null,
    );
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.marketComparisonTitle,
        actions: [
          MbAppBarAction(
            icon: MbIcons.market,
            label: l10n.browseByMandi,
            onPressed: () => context.push(AppRoutes.mandiPrices),
          ),
          MbAppBarAction(
            icon: MbIcons.watchlist,
            label: watched ? l10n.removeFromWatchlist : l10n.addToWatchlist,
            selected: watched,
            onPressed: commodityId == null
                ? null
                : () => toggleWatch(context, commodityId),
          ),
        ],
      ),
      body: BlocBuilder<MarketComparisonCubit, MarketComparisonState>(
        builder: (context, state) {
          final cubit = context.read<MarketComparisonCubit>();
          final comparison = state.comparison;
          return switch (state.status) {
            LoadStatus.failure => MbErrorView(
              failure: state.failure!,
              onRetry: cubit.load,
            ),
            LoadStatus.ready when comparison == null => MbEmptyView(
              message: l10n.comparisonEmpty,
              onRetry: cubit.load,
            ),
            LoadStatus.ready => _Content(state: state, comparison: comparison!),
            _ => const MbLoadingView(),
          };
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.comparison});

  final MarketComparisonState state;
  final MarketComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MarketComparisonCubit>();
    final best = comparison.rowFor(comparison.bestMarketId);
    final home = comparison.rowFor(comparison.homeMarketId);
    final saving = best != null && home != null && best != home
        ? home.price - best.price
        : null;
    const gap = SizedBox(height: 14);

    return Stack(
      children: [
        ListView(
          padding: MbSpacing.screenPadding,
          children: [
            if (state.categories.isNotEmpty) ...[
              MbChipGroup<String>.single(
                semanticLabel: l10n.categoryLabel,
                value: state.categoryCode ?? '',
                onChanged: (code) =>
                    cubit.selectCategory(code.isEmpty ? null : code),
                options: [
                  for (final category in state.categories)
                    MbChipOption(value: category.code, label: category.name),
                  MbChipOption(value: '', label: l10n.filterAll),
                ],
              ),
              gap,
            ],
            MbSelectField<String>(
              icon: categoryIcon(state.commodity?.categoryCode ?? ''),
              hint: l10n.commodityLabel,
              value: state.commodityId,
              onChanged: cubit.selectCommodity,
              items: [
                for (final c in state.visibleCommodities)
                  MbSelectItem(value: c.id, label: c.name),
              ],
            ),
            gap,
            MbChipGroup<String>.multiple(
              semanticLabel: l10n.marketsLabel,
              values: comparison.selectedMarketIds.toSet(),
              onChanged: cubit.selectMarkets,
              options: [
                for (final m in comparison.availableMarkets)
                  MbChipOption(value: m.id, label: m.name),
              ],
            ),
            gap,
            if (comparison.rows.isEmpty)
              MbEmptyView(message: l10n.comparisonEmpty)
            else
              MbPriceTable(
                nameHeader: l10n.columnMarket,
                priceHeader: l10n.columnPricePer(comparison.unit),
                changeHeader: l10n.columnChange,
                rows: [
                  for (final row in comparison.rows)
                    MbPriceRow(
                      name: row.marketName,
                      meta: row.arrivals == null
                          ? null
                          : l10n.arrivals(row.arrivals!),
                      price: formatInr(row.price),
                      change: row.change,
                      changeCurrency: false,
                      best: row.marketId == comparison.bestMarketId,
                      badge: row.marketId == state.highlightMarketId
                          ? MbBadge(
                              label: l10n.fromLink,
                              tone: MbBadgeTone.opportunity,
                            )
                          : null,
                      onShare: () => sharePriceCard(
                        context,
                        PriceShareData(
                          productName: state.commodity?.name ?? '',
                          mandiName: row.marketName,
                          minPrice: row.minPrice,
                          maxPrice: row.maxPrice,
                          modalPrice: row.price,
                          unitSymbol: comparison.unit,
                          recordDate: row.recordDate,
                          source: row.source,
                          link: DeepLinkConfig.productLink(
                            comparison.commodityId,
                            mandiId: row.marketId,
                          ),
                        ),
                      ),
                      shareLabel: l10n.sharePrice,
                      onTap: () => context.go(
                        AppRoutes.trendsFor(
                          comparison.commodityId,
                          row.marketId,
                        ),
                      ),
                    ),
                ],
              ),
            if (best != null) ...[
              gap,
              MbHighlightPanel(
                tone: MbTone.amber,
                label: l10n.bestMarket(best.marketName),
                value: formatInr(best.price),
                unit: '/${comparison.unit}',
                caption: saving == null || saving <= 0
                    ? null
                    : l10n.lowerThanYourMarket(
                        formatInr(saving),
                        home!.marketName,
                      ),
              ),
            ],
            gap,
            MbSourceNote(
              source: comparison.source,
              updated: context.updatedAt(comparison.updatedAt),
            ),
            // Below the data, after the source note: never between prices.
            const AdSlot(placement: PromotionPlacement.marketComparison),
          ],
        ),
        if (state.refreshing) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
