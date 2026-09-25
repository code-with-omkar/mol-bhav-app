import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/watchlist.dart';

class WatchlistState extends Equatable {
  const WatchlistState({this.data = const DataState(), this.category});

  final DataState<Watchlist> data;

  /// Selected category code; `null` = All.
  final String? category;

  List<WatchlistItem> get visibleItems => [
    for (final item in data.data?.items ?? const <WatchlistItem>[])
      if (category == null || item.categoryCode == category) item,
  ];

  @override
  List<Object?> get props => [data, category];
}

@injectable
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._getWatchlist) : super(const WatchlistState());

  final GetWatchlist _getWatchlist;

  Future<void> load() async {
    emit(
      WatchlistState(
        data: DataState.loading(data: state.data.data),
        category: state.category,
      ),
    );
    final result = await _getWatchlist();
    emit(
      WatchlistState(
        data: DataState.fromResult(result),
        category: state.category,
      ),
    );
  }

  void selectCategory(String? code) =>
      emit(WatchlistState(data: state.data, category: code));
}

/// Tracked items across categories, each with a sparkline.
class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.watchlistTitle,
        // Search and add-item have no screens in the design yet.
        actions: [
          MbAppBarAction(
            icon: MbIcons.search,
            label: l10n.search,
            onPressed: null,
          ),
          MbAppBarAction(
            icon: MbIcons.plus,
            label: l10n.addItem,
            onPressed: null,
          ),
        ],
      ),
      body: BlocBuilder<WatchlistCubit, WatchlistState>(
        builder: (context, state) {
          final cubit = context.read<WatchlistCubit>();
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
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
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
                MbGroup(
                  children: [
                    for (final item in state.visibleItems)
                      MbPriceRow(
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
                          AppRoutes.trendsFor(item.commodityId, item.marketId),
                        ),
                      ),
                  ],
                ),
                if (data.updatedAt != null) ...[
                  const SizedBox(height: 14),
                  MbSourceNote(updated: context.updatedAt(data.updatedAt!)),
                ],
              ],
            ),
          );
        },
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
