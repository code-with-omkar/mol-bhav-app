import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_commodities.dart';
import '../domain/admin_ingestion.dart';

/// The source whose feed list is used, that list, and where products can go.
class CommoditiesSetup extends Equatable {
  const CommoditiesSetup({
    required this.sourceId,
    required this.options,
    required this.targets,
  });

  final String sourceId;
  final FilterOptions options;
  final CommodityTargets targets;

  @override
  List<Object?> get props => [sourceId, options, targets];
}

class AdminCommoditiesState extends Equatable {
  const AdminCommoditiesState({
    this.setup = const DataState(),
    this.importing = false,
    this.result,
    this.importFailure,
  });

  final DataState<CommoditiesSetup> setup;

  /// An import is in flight.
  final bool importing;

  /// What the last import did; shown until the next one.
  final ImportCommoditiesResult? result;

  /// Why the last import was refused (shown once, then cleared).
  final Failure? importFailure;

  AdminCommoditiesState copyWith({
    DataState<CommoditiesSetup>? setup,
    bool? importing,
    ImportCommoditiesResult? Function()? result,
    Failure? Function()? importFailure,
  }) => AdminCommoditiesState(
    setup: setup ?? this.setup,
    importing: importing ?? this.importing,
    result: result != null ? result() : this.result,
    importFailure: importFailure != null ? importFailure() : this.importFailure,
  );

  @override
  List<Object?> get props => [setup, importing, result, importFailure];
}

/// Adds commodities from the Agmarknet feed list to the catalog as products.
@injectable
class AdminCommoditiesCubit extends Cubit<AdminCommoditiesState> {
  AdminCommoditiesCubit(this._ingestion, this._commodities)
    : super(const AdminCommoditiesState());

  /// The only source whose commodity names map onto product codes.
  static const sourceCode = 'agmarknet';

  final AdminIngestionRepository _ingestion;
  final AdminCommoditiesRepository _commodities;

  Future<void> load() async {
    emit(state.copyWith(setup: DataState.loading(data: state.setup.data)));
    final schedules = await _ingestion.getSchedules();
    if (isClosed) return;
    final source = schedules.fold(
      (_) => null,
      (items) => items.where((s) => s.sourceCode == sourceCode).firstOrNull,
    );
    if (source == null) {
      // Either the list failed to load or the source does not exist.
      emit(
        state.copyWith(
          setup: schedules.fold(
            (failure) =>
                DataState(status: LoadStatus.failure, failure: failure),
            (_) => const DataState(
              status: LoadStatus.failure,
              failure: UnexpectedFailure(),
            ),
          ),
        ),
      );
      return;
    }
    final options = await _ingestion.getFilterOptions(source.sourceId);
    final targets = await _commodities.getTargets();
    if (isClosed) return;
    emit(
      state.copyWith(
        setup: options.fold(
          (failure) => DataState(status: LoadStatus.failure, failure: failure),
          (o) => targets.fold(
            (failure) =>
                DataState(status: LoadStatus.failure, failure: failure),
            (t) => DataState.ready(
              CommoditiesSetup(
                sourceId: source.sourceId,
                options: o,
                targets: t,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> importCommodities({
    required String subCategoryId,
    required String unitId,
    required List<String> commodities,
  }) async {
    final setup = state.setup.data;
    if (setup == null || state.importing || commodities.isEmpty) return;
    emit(
      state.copyWith(
        importing: true,
        result: () => null,
        importFailure: () => null,
      ),
    );
    final outcome = await _commodities.importFeedProducts(
      sourceId: setup.sourceId,
      subCategoryId: subCategoryId,
      unitId: unitId,
      commodities: commodities,
    );
    if (isClosed) return;
    outcome.fold(
      (failure) =>
          emit(state.copyWith(importing: false, importFailure: () => failure)),
      (result) => emit(state.copyWith(importing: false, result: () => result)),
    );
  }

  void failureShown() => emit(state.copyWith(importFailure: () => null));
}
