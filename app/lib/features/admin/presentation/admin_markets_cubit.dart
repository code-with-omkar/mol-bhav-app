import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ingestion.dart';
import '../domain/admin_markets.dart';

/// The source whose feed list is used, with that list.
class MarketsSetup extends Equatable {
  const MarketsSetup({required this.sourceId, required this.options});

  final String sourceId;
  final FilterOptions options;

  @override
  List<Object?> get props => [sourceId, options];
}

class AdminMarketsState extends Equatable {
  const AdminMarketsState({
    this.setup = const DataState(),
    this.importing = false,
    this.result,
    this.importFailure,
  });

  final DataState<MarketsSetup> setup;

  /// An import is in flight.
  final bool importing;

  /// What the last import did; shown until the next one.
  final ImportMarketsResult? result;

  /// Why the last import was refused (shown once, then cleared).
  final Failure? importFailure;

  AdminMarketsState copyWith({
    DataState<MarketsSetup>? setup,
    bool? importing,
    ImportMarketsResult? Function()? result,
    Failure? Function()? importFailure,
  }) => AdminMarketsState(
    setup: setup ?? this.setup,
    importing: importing ?? this.importing,
    result: result != null ? result() : this.result,
    importFailure: importFailure != null ? importFailure() : this.importFailure,
  );

  @override
  List<Object?> get props => [setup, importing, result, importFailure];
}

/// Adds markets from the Agmarknet feed list to the catalog.
@injectable
class AdminMarketsCubit extends Cubit<AdminMarketsState> {
  AdminMarketsCubit(this._ingestion, this._markets)
    : super(const AdminMarketsState());

  /// The only source whose market names map onto mandi codes.
  static const sourceCode = 'agmarknet';

  final AdminIngestionRepository _ingestion;
  final AdminMarketsRepository _markets;

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
    if (isClosed) return;
    emit(
      state.copyWith(
        setup: options.fold(
          (failure) => DataState(status: LoadStatus.failure, failure: failure),
          (o) => DataState.ready(
            MarketsSetup(sourceId: source.sourceId, options: o),
          ),
        ),
      ),
    );
  }

  Future<void> importMarkets(String stateName, List<String> markets) async {
    final setup = state.setup.data;
    if (setup == null || state.importing || markets.isEmpty) return;
    emit(
      state.copyWith(
        importing: true,
        result: () => null,
        importFailure: () => null,
      ),
    );
    final outcome = await _markets.importFeedMarkets(
      sourceId: setup.sourceId,
      state: stateName,
      markets: markets,
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
