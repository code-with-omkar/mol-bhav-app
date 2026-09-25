import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/tools.dart';

class CostEstimatorState extends Equatable {
  const CostEstimatorState({
    this.options = const DataState(),
    this.categoryCode,
    this.materialId,
    this.unitId,
    this.locationId,
    this.quantityText = '',
    this.estimate = const DataState(),
    this.saveStatus = SubmitStatus.idle,
    this.saveFailure,
  });

  final DataState<EstimatorOptions> options;
  final String? categoryCode;
  final String? materialId;
  final String? unitId;
  final String? locationId;
  final String quantityText;
  final DataState<Estimate> estimate;
  final SubmitStatus saveStatus;
  final Failure? saveFailure;

  List<EstimatorMaterial> get materials => [
    for (final m in options.data?.materials ?? const <EstimatorMaterial>[])
      if (m.categoryCode == categoryCode) m,
  ];

  EstimatorMaterial? get material =>
      materials.where((m) => m.id == materialId).firstOrNull;

  EstimateRequest? get request {
    final quantity = num.tryParse(quantityText);
    if (materialId == null ||
        unitId == null ||
        locationId == null ||
        quantity == null ||
        quantity <= 0) {
      return null;
    }
    return EstimateRequest(
      materialId: materialId!,
      quantity: quantity,
      unitId: unitId!,
      locationId: locationId!,
    );
  }

  bool get canSave =>
      estimate.status == LoadStatus.ready &&
      saveStatus != SubmitStatus.submitting;

  CostEstimatorState copyWith({
    DataState<EstimatorOptions>? options,
    String? categoryCode,
    String? materialId,
    String? unitId,
    String? locationId,
    String? quantityText,
    DataState<Estimate>? estimate,
    SubmitStatus? saveStatus,
    Failure? saveFailure,
  }) => CostEstimatorState(
    options: options ?? this.options,
    categoryCode: categoryCode ?? this.categoryCode,
    materialId: materialId ?? this.materialId,
    unitId: unitId ?? this.unitId,
    locationId: locationId ?? this.locationId,
    quantityText: quantityText ?? this.quantityText,
    estimate: estimate ?? this.estimate,
    saveStatus: saveStatus ?? SubmitStatus.idle,
    saveFailure: saveFailure,
  );

  @override
  List<Object?> get props => [
    options,
    categoryCode,
    materialId,
    unitId,
    locationId,
    quantityText,
    estimate,
    saveStatus,
    saveFailure,
  ];
}

@injectable
class CostEstimatorCubit extends Cubit<CostEstimatorState> {
  CostEstimatorCubit(this._getOptions, this._calculate, this._save)
    : super(const CostEstimatorState());

  final GetEstimatorOptions _getOptions;
  final CalculateEstimate _calculate;
  final SaveEstimate _save;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(options: const DataState.loading()));
    final options = DataState.fromResult(await _getOptions());
    final data = options.data;
    emit(
      state.copyWith(
        options: options,
        locationId: data?.locations.firstOrNull?.id,
      ),
    );
    final first = data?.categories.firstOrNull;
    if (first != null) selectCategory(first.id);
  }

  void selectCategory(String code) {
    final next = CostEstimatorState(
      options: state.options,
      categoryCode: code,
      locationId: state.locationId,
      quantityText: state.quantityText,
    );
    final material = next.materials.firstOrNull;
    emit(
      next.copyWith(
        materialId: material?.id,
        unitId: material?.units.firstOrNull?.id,
      ),
    );
    _schedule();
  }

  void selectMaterial(String id) {
    final material = state.materials.where((m) => m.id == id).firstOrNull;
    emit(
      state.copyWith(materialId: id, unitId: material?.units.firstOrNull?.id),
    );
    _schedule();
  }

  void selectUnit(String id) {
    emit(state.copyWith(unitId: id));
    _schedule();
  }

  void selectLocation(String id) {
    emit(state.copyWith(locationId: id));
    _schedule();
  }

  void quantityChanged(String text) {
    emit(state.copyWith(quantityText: text.trim()));
    _schedule();
  }

  Future<void> retryEstimate() => _estimate();

  Future<void> save() async {
    final request = state.request;
    if (request == null || !state.canSave) return;
    emit(state.copyWith(saveStatus: SubmitStatus.submitting));
    final result = await _save(request);
    emit(
      result.fold(
        (f) => state.copyWith(saveStatus: SubmitStatus.failure, saveFailure: f),
        (_) => state.copyWith(saveStatus: SubmitStatus.success),
      ),
    );
  }

  /// Recalculates shortly after the user stops editing.
  void _schedule() {
    _debounce?.cancel();
    if (state.request == null) {
      emit(state.copyWith(estimate: const DataState()));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _estimate);
  }

  Future<void> _estimate() async {
    final request = state.request;
    if (request == null) return;
    emit(
      state.copyWith(estimate: DataState.loading(data: state.estimate.data)),
    );
    final result = await _calculate(request);
    if (isClosed || state.request != request) return;
    emit(state.copyWith(estimate: DataState.fromResult(result)));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

@injectable
class ReportsCubit extends Cubit<DataState<ReportsOverview>> {
  ReportsCubit(this._getReports) : super(const DataState());

  final GetReports _getReports;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    emit(DataState.fromResult(await _getReports()));
  }
}
