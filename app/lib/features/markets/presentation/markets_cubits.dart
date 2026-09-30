import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../account/presentation/profile_cubit.dart';
import '../../catalog/domain/catalog.dart';
import '../domain/markets_entities.dart';
import '../domain/markets_repository.dart';

class MarketComparisonState extends Equatable {
  const MarketComparisonState({
    this.status = LoadStatus.initial,
    this.failure,
    this.commodities = const [],
    this.categories = const [],
    this.categoryCode,
    this.commodityId,
    this.comparison,
    this.refreshing = false,
    this.highlightMarketId,
  });

  final LoadStatus status;
  final Failure? failure;
  final List<Commodity> commodities;

  /// Category chips, the user's own procurement categories first.
  final List<CatalogCategory> categories;

  /// Selected category; `null` shows every category's products.
  final String? categoryCode;
  final String? commodityId;
  final MarketComparison? comparison;

  /// A new commodity or market set is loading over the current result.
  final bool refreshing;

  /// The mandi a deep link named, badged in the table so the person who
  /// followed the link sees which row the sender meant.
  final String? highlightMarketId;

  /// The products the category chips currently allow through.
  List<Commodity> get visibleCommodities => categoryCode == null
      ? commodities
      : [
          for (final c in commodities)
            if (c.categoryCode == categoryCode) c,
        ];

  Commodity? get commodity =>
      commodities.where((c) => c.id == commodityId).firstOrNull;

  MarketComparisonState copyWith({
    LoadStatus? status,
    Failure? failure,
    List<Commodity>? commodities,
    List<CatalogCategory>? categories,
    ValueGetter<String?>? categoryCode,
    String? commodityId,
    MarketComparison? comparison,
    bool? refreshing,
    String? highlightMarketId,
  }) => MarketComparisonState(
    status: status ?? this.status,
    failure: failure,
    commodities: commodities ?? this.commodities,
    categories: categories ?? this.categories,
    categoryCode: categoryCode != null ? categoryCode() : this.categoryCode,
    commodityId: commodityId ?? this.commodityId,
    comparison: comparison ?? this.comparison,
    refreshing: refreshing ?? false,
    highlightMarketId: highlightMarketId ?? this.highlightMarketId,
  );

  @override
  List<Object?> get props => [
    status,
    failure,
    commodities,
    categories,
    categoryCode,
    commodityId,
    comparison,
    refreshing,
    highlightMarketId,
  ];
}

@injectable
class MarketComparisonCubit extends Cubit<MarketComparisonState> {
  MarketComparisonCubit(
    this._getCommodities,
    this._getComparison,
    this._catalog,
    this._profile,
  ) : super(const MarketComparisonState());

  final GetCommodities _getCommodities;
  final GetMarketComparison _getComparison;
  final CatalogRepository _catalog;
  final ProfileCubit _profile;

  /// Opens on [commodityId], else the first commodity of [categoryCode],
  /// else the first commodity of the user's own first category.
  /// [highlightMarketId] comes from a shared deep link.
  Future<void> load({
    String? commodityId,
    String? categoryCode,
    String? highlightMarketId,
  }) async {
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        highlightMarketId: highlightMarketId,
      ),
    );
    await _profile.ensureLoaded();
    final (result, categoryResult) = await (
      _getCommodities(),
      _catalog.getCategories(),
    ).wait;
    if (isClosed) return;
    final commodities = result.fold((_) => null, (list) => list);
    if (commodities == null) {
      emit(
        state.copyWith(
          status: LoadStatus.failure,
          failure: result.fold((f) => f, (_) => null),
        ),
      );
      return;
    }
    final categories = _orderCategories(
      categoryResult.fold((_) => const <CatalogCategory>[], (list) => list),
      commodities,
    );
    // The route's category wins, then the opened commodity's, then the user's own.
    var selected =
        categoryCode ??
        commodities
            .where((c) => c.id == commodityId)
            .firstOrNull
            ?.categoryCode ??
        categories.firstOrNull?.code;
    final initial =
        commodities.where((c) => c.id == commodityId).firstOrNull ??
        commodities.where((c) => c.categoryCode == selected).firstOrNull ??
        commodities.firstOrNull;
    // A category with nothing in it would show an empty picker: fall back to All.
    if (initial != null && initial.categoryCode != selected) selected = null;
    if (initial == null) {
      emit(
        state.copyWith(
          status: LoadStatus.ready,
          commodities: commodities,
          categories: categories,
          categoryCode: () => selected,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        commodities: commodities,
        categories: categories,
        categoryCode: () => selected,
        commodityId: initial.id,
      ),
    );
    await _compare(initial.id, null);
  }

  /// `null` selects every category. Moves to that category's first product
  /// when the current one isn't in it.
  Future<void> selectCategory(String? code) async {
    if (code == state.categoryCode) return;
    emit(state.copyWith(categoryCode: () => code));
    final current = state.commodity;
    if (code == null || current?.categoryCode == code) return;
    final first = state.visibleCommodities.firstOrNull;
    if (first == null) return;
    await selectCommodity(first.id);
  }

  Future<void> selectCommodity(String id) async {
    if (id == state.commodityId) return;
    emit(state.copyWith(commodityId: id, refreshing: true));
    await _compare(id, null);
  }

  /// The user's own procurement categories first, then the rest — and only
  /// categories that actually have products to show.
  List<CatalogCategory> _orderCategories(
    List<CatalogCategory> categories,
    List<Commodity> commodities,
  ) {
    final stocked = {for (final c in commodities) c.categoryCode};
    final mine = _profile.state.data?.categoryCodes ?? const <String>[];
    final available = [
      for (final c in categories)
        if (stocked.contains(c.code)) c,
    ];
    return [
      for (final code in mine) ...available.where((c) => c.code == code),
      for (final c in available)
        if (!mine.contains(c.code)) c,
    ];
  }

  Future<void> selectMarkets(Set<String> marketIds) async {
    final id = state.commodityId;
    if (id == null || marketIds.isEmpty) return;
    emit(state.copyWith(refreshing: true));
    await _compare(id, marketIds.toList());
  }

  /// Shows the cached comparison at once and keeps [MarketComparisonState.refreshing]
  /// on until the live one arrives.
  Future<void> _compare(String commodityId, List<String>? marketIds) async {
    await for (final next in revalidate(
      _getComparison(commodityId, marketIds: marketIds),
    )) {
      if (isClosed || state.commodityId != commodityId) return;
      final comparison = next.data;
      if (next.status == LoadStatus.failure && comparison == null) {
        emit(state.copyWith(status: LoadStatus.failure, failure: next.failure));
      } else if (comparison != null) {
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            comparison: comparison,
            refreshing: next.isLoading,
          ),
        );
      }
    }
  }
}

class PriceTrendsState extends Equatable {
  const PriceTrendsState({
    this.range = TrendRange.month,
    this.data = const DataState(),
  });

  final TrendRange range;
  final DataState<PriceTrend> data;

  @override
  List<Object?> get props => [range, data];
}

@injectable
class PriceTrendsCubit extends Cubit<PriceTrendsState> {
  PriceTrendsCubit(this._getTrend) : super(const PriceTrendsState());

  final GetPriceTrend _getTrend;
  String? _commodityId;
  String? _marketId;

  Future<void> load(String commodityId, String marketId) {
    _commodityId = commodityId;
    _marketId = marketId;
    return _fetch();
  }

  Future<void> selectRange(TrendRange range) {
    if (range == state.range) return Future.value();
    emit(PriceTrendsState(range: range, data: state.data));
    return _fetch();
  }

  Future<void> retry() => _fetch();

  Future<void> _fetch() async {
    final commodityId = _commodityId, marketId = _marketId;
    if (commodityId == null || marketId == null) return;
    final range = state.range;
    emit(
      PriceTrendsState(
        range: range,
        data: DataState.loading(data: state.data.data),
      ),
    );
    final result = await _getTrend(commodityId, marketId, range);
    if (isClosed || state.range != range) return;
    emit(PriceTrendsState(range: range, data: DataState.fromResult(result)));
  }
}

@injectable
class BuyingOpportunityCubit extends Cubit<DataState<BuyingOpportunity>> {
  BuyingOpportunityCubit(this._getOpportunity) : super(const DataState());

  final GetBuyingOpportunity _getOpportunity;
  String? _id;

  Future<void> load(String id) async {
    _id = id;
    emit(const DataState.loading());
    emit(DataState.fromResult(await _getOpportunity(id)));
  }

  Future<void> retry() async {
    if (_id != null) await load(_id!);
  }
}
