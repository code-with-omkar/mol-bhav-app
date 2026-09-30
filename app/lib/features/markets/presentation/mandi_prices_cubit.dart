import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/mandi_prices.dart';

class MandiPricesState extends Equatable {
  const MandiPricesState({
    this.states = const DataState(),
    this.districts = const DataState(),
    this.mandis = const DataState(),
    this.prices = const DataState(),
    this.stateId,
    this.districtId,
    this.mandiId,
  });

  final DataState<List<LocationOption>> states;
  final DataState<List<LocationOption>> districts;
  final DataState<List<LocationOption>> mandis;
  final DataState<List<MandiPrice>> prices;
  final String? stateId;
  final String? districtId;
  final String? mandiId;

  /// Name of the selected mandi, for the screen's shared price cards.
  String? get mandiName =>
      mandis.data?.where((m) => m.id == mandiId).firstOrNull?.name;

  MandiPricesState copyWith({
    DataState<List<LocationOption>>? states,
    DataState<List<LocationOption>>? districts,
    DataState<List<LocationOption>>? mandis,
    DataState<List<MandiPrice>>? prices,
    ValueGetter<String?>? stateId,
    ValueGetter<String?>? districtId,
    ValueGetter<String?>? mandiId,
  }) => MandiPricesState(
    states: states ?? this.states,
    districts: districts ?? this.districts,
    mandis: mandis ?? this.mandis,
    prices: prices ?? this.prices,
    stateId: stateId != null ? stateId() : this.stateId,
    districtId: districtId != null ? districtId() : this.districtId,
    mandiId: mandiId != null ? mandiId() : this.mandiId,
  );

  @override
  List<Object?> get props => [
    states,
    districts,
    mandis,
    prices,
    stateId,
    districtId,
    mandiId,
  ];
}

@injectable
class MandiPricesCubit extends Cubit<MandiPricesState> {
  MandiPricesCubit(this._get) : super(const MandiPricesState());

  final GetMandiPrices _get;

  Future<void> load() async {
    emit(state.copyWith(states: const DataState.loading()));
    emit(state.copyWith(states: DataState.fromResult(await _get.states())));
  }

  Future<void> selectState(String id) async {
    if (id == state.stateId) return;
    emit(
      MandiPricesState(
        states: state.states,
        stateId: id,
        districts: const DataState.loading(),
      ),
    );
    final result = await _get.districts(id);
    if (isClosed || state.stateId != id) return;
    emit(state.copyWith(districts: DataState.fromResult(result)));
  }

  Future<void> selectDistrict(String id) async {
    if (id == state.districtId) return;
    emit(
      MandiPricesState(
        states: state.states,
        stateId: state.stateId,
        districts: state.districts,
        districtId: id,
        mandis: const DataState.loading(),
      ),
    );
    final result = await _get.mandis(id);
    if (isClosed || state.districtId != id) return;
    emit(state.copyWith(mandis: DataState.fromResult(result)));
  }

  Future<void> selectMandi(String id) async {
    emit(state.copyWith(mandiId: () => id, prices: const DataState.loading()));
    await _loadPrices(id);
  }

  Future<void> retry() async {
    if (state.states.data == null) return load();
    final mandiId = state.mandiId;
    if (mandiId != null) return _loadPrices(mandiId);
  }

  Future<void> _loadPrices(String mandiId) async {
    final Result<List<MandiPrice>> result = await _get.prices(mandiId);
    if (isClosed || state.mandiId != mandiId) return;
    emit(state.copyWith(prices: DataState.fromResult(result)));
  }
}
