import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/watchlist.dart';
import 'watch_star.dart';
import 'watchlist_cubit.dart';

/// Tracked items across categories. Search filters the list locally; "+"
/// opens the product picker; swiping a row removes it (with Undo).
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    context.read<WatchlistCubit>().ensureLoaded();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _search.clear();
      context.read<WatchlistCubit>().search('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<WatchlistCubit>();
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.watchlistTitle,
        actions: [
          MbAppBarAction(
            icon: _searching ? MbIcons.close : MbIcons.search,
            label: l10n.search,
            onPressed: _toggleSearch,
          ),
          MbAppBarAction(
            icon: MbIcons.plus,
            label: l10n.addItem,
            onPressed: () => context.push(AppRoutes.watchlistAdd),
          ),
        ],
      ),
      body: BlocBuilder<WatchlistCubit, WatchlistState>(
        builder: (context, state) {
          final data = state.data.data;
          if (data == null) {
            return state.data.status == LoadStatus.failure
                ? MbErrorView(failure: state.data.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          if (data.items.isEmpty) {
            return MbEmptyView(
              message: l10n.watchlistEmpty,
              onRetry: cubit.load,
            );
          }
          final items = state.visibleItems;
          return MbRevalidating(
            active: state.data.isRevalidating,
            child: RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: MbSpacing.screenPadding,
                children: [
                  if (_searching) ...[
                    MbTextField(
                      controller: _search,
                      hint: l10n.searchWatchlistHint,
                      icon: MbIcons.search,
                      textInputAction: TextInputAction.search,
                      onChanged: cubit.search,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (data.categories.isNotEmpty) ...[
                    MbSegmentedTabs<String?>(
                      value: state.category,
                      onChanged: cubit.selectCategory,
                      options: [
                        MbTabOption(value: null, label: l10n.filterAll),
                        for (final c in data.categories)
                          MbTabOption(value: c.code, label: c.name),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (items.isEmpty)
                    Text(
                      l10n.noMatches,
                      style: context.mbText.body.copyWith(
                        color: context.mbColors.inkMuted,
                      ),
                    )
                  else
                    MbGroup(
                      children: [
                        for (final item in items) _SwipeRow(item: item),
                      ],
                    ),
                  if (data.updatedAt != null) ...[
                    const SizedBox(height: 14),
                    MbSourceNote(updated: context.updatedAt(data.updatedAt!)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwipeRow extends StatelessWidget {
  const _SwipeRow({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.priceUp,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s5),
        child: MbIcon(
          MbIcons.close,
          color: c.inkOnHero,
          semanticLabel: l10n.removeFromWatchlist,
        ),
      ),
      onDismissed: (_) async {
        final result = await context.read<WatchlistCubit>().remove(item);
        if (context.mounted) {
          showWatchlistResult(context, result, removed: item);
        }
      },
      child: MbPriceRow(
        thumb: categoryIcon(item.categoryCode),
        thumbTone: categoryTint(item.categoryCode),
        name: item.name,
        meta: _meta(context, item),
        price: formatInr(item.price),
        unit: item.unit,
        percent: item.percent,
        stacked: true,
        trend: item.trend.length > 1 ? item.trend : null,
        onTap: () => context.go(
          item.marketId.isEmpty
              ? AppRoutes.marketsFor(commodityId: item.commodityId)
              : AppRoutes.trendsFor(item.commodityId, item.marketId),
        ),
      ),
    );
  }

  /// `Pune · alert below ₹2,000`, `Fe 500D · Pune`.
  String? _meta(BuildContext context, WatchlistItem item) {
    final l10n = context.l10n;
    final value = item.alertValue;
    final parts = [
      ?item.variety,
      ?item.marketName,
      if (value != null && item.alertCondition == AlertCondition.below)
        l10n.alertBelow(formatInr(value)),
      if (value != null && item.alertCondition == AlertCondition.above)
        l10n.alertAbove(formatInr(value)),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
