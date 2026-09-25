import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/markets_entities.dart';
import '../domain/markets_repository.dart';

class MarketComparisonState extends Equatable {
  const MarketComparisonState({
    this.status = LoadStatus.initial,
    this.failure,
    this.commodities = const [],
    this.commodityId,
    this.comparison,
    this.refreshing = false,
  });

  final LoadStatus status;
  final Failure? failure;
  final List<Commodity> commodities;
  final String? commodityId;
  final MarketComparison? comparison;

  /// A new commodity or market set is loading over the current result.
  final bool refreshing;

  MarketComparisonState copyWith({
    LoadStatus? status,
    Failure? failure,
    List<Commodity>? commodities,
    String? commodityId,
    MarketComparison? comparison,
    bool? refreshing,
  }) => MarketComparisonState(
    status: status ?? this.status,
    failure: failure,
    commodities: commodities ?? this.commodities,
    commodityId: commodityId ?? this.commodityId,
    comparison: comparison ?? this.comparison,
    refreshing: refreshing ?? false,
  );

  @override
  List<Object?> get props => [
    status,
    failure,
    commodities,
    commodityId,
    comparison,
    refreshing,
  ];
}

@injectable
class MarketComparisonCubit extends Cubit<MarketComparisonState> {
  MarketComparisonCubit(this._getCommodities, this._getComparison)
    : super(const MarketComparisonState());

  final GetCommodities _getCommodities;
  final GetMarketComparison _getComparison;

  /// Opens on [commodityId], else the first commodity of [categoryCode],
  /// else the first commodity.
  Future<void> load({String? commodityId, String? categoryCode}) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _getCommodities();
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
    final initial =
        commodities.where((c) => c.id == commodityId).firstOrNull ??
        commodities.where((c) => c.categoryCode == categoryCode).firstOrNull ??
        commodities.firstOrNull;
    if (initial == null) {
      emit(state.copyWith(status: LoadStatus.ready, commodities: commodities));
      return;
    }
    emit(state.copyWith(commodities: commodities, commodityId: initial.id));
    await _compare(initial.id, null);
  }

  Future<void> selectCommodity(String id) async {
    if (id == state.commodityId) return;
    emit(state.copyWith(commodityId: id, refreshing: true));
    await _compare(id, null);
  }

  Future<void> selectMarkets(Set<String> marketIds) async {
    final id = state.commodityId;
    if (id == null || marketIds.isEmpty) return;
    emit(state.copyWith(refreshing: true));
    await _compare(id, marketIds.toList());
  }

  Future<void> _compare(String commodityId, List<String>? marketIds) async {
    final result = await _getComparison(commodityId, marketIds: marketIds);
    if (isClosed || state.commodityId != commodityId) return;
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: LoadStatus.failure, failure: failure),
        (comparison) =>
            state.copyWith(status: LoadStatus.ready, comparison: comparison),
      ),
    );
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
