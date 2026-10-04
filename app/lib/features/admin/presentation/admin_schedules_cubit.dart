import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ingestion.dart';

enum AdminActionKind { saved, ran }

class AdminSchedulesState extends Equatable {
  const AdminSchedulesState({
    this.items = const DataState(),
    this.busySourceIds = const {},
    this.actionFailure,
    this.lastAction,
    this.actionSeq = 0,
  });

  final DataState<List<IngestionScheduleItem>> items;

  /// Sources with a save or run in flight; their buttons are disabled.
  final Set<String> busySourceIds;
  final Failure? actionFailure;
  final AdminActionKind? lastAction;

  /// Bumps on every action result so the page shows each snackbar once.
  final int actionSeq;

  AdminSchedulesState copyWith({
    DataState<List<IngestionScheduleItem>>? items,
    Set<String>? busySourceIds,
    Failure? actionFailure,
    AdminActionKind? lastAction,
    bool bumpSeq = false,
  }) => AdminSchedulesState(
    items: items ?? this.items,
    busySourceIds: busySourceIds ?? this.busySourceIds,
    actionFailure: actionFailure,
    lastAction: lastAction,
    actionSeq: bumpSeq ? actionSeq + 1 : actionSeq,
  );

  @override
  List<Object?> get props => [
    items,
    busySourceIds,
    actionFailure,
    lastAction,
    actionSeq,
  ];
}

/// Price-source schedules: list, edit, enable/disable and "Run now".
class AdminSchedulesCubit extends Cubit<AdminSchedulesState> {
  AdminSchedulesCubit(this._repository) : super(const AdminSchedulesState());

  final AdminIngestionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(items: DataState.loading(data: state.items.data)));
    final result = await _repository.getSchedules();
    if (isClosed) return;
    emit(state.copyWith(items: _merge(result)));
  }

  Future<void> save(String sourceId, ScheduleInput input) => _act(
    sourceId,
    AdminActionKind.saved,
    () => _repository.saveSchedule(sourceId, input),
  );

  /// Flips only the enabled flag, keeping the rest of the schedule.
  Future<void> setEnabled(IngestionScheduleItem item, bool enabled) =>
      save(item.sourceId, item.toInput().copyWith(isEnabled: enabled));

  Future<void> runNow(String sourceId) =>
      _act(sourceId, AdminActionKind.ran, () => _repository.runNow(sourceId));

  Future<void> _act(
    String sourceId,
    AdminActionKind kind,
    Future<Result<void>> Function() call,
  ) async {
    if (state.busySourceIds.contains(sourceId)) return;
    emit(state.copyWith(busySourceIds: {...state.busySourceIds, sourceId}));

    final result = await call();
    if (isClosed) return;

    // Reload either way: a run changes the last job, a save the next run, and
    // a failed save shows what the server actually holds.
    final reloaded = await _repository.getSchedules();
    if (isClosed) return;

    emit(
      state.copyWith(
        items: _merge(reloaded),
        busySourceIds: {...state.busySourceIds}..remove(sourceId),
        actionFailure: switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
        lastAction: result is Ok ? kind : null,
        bumpSeq: true,
      ),
    );
  }

  /// A failed reload keeps the list already on screen.
  DataState<List<IngestionScheduleItem>> _merge(
    Result<List<IngestionScheduleItem>> result,
  ) => switch (result) {
    Ok(:final value) => DataState.ready(value),
    Err(:final failure) => DataState(
      status: LoadStatus.failure,
      data: state.items.data,
      failure: failure,
    ),
  };
}
