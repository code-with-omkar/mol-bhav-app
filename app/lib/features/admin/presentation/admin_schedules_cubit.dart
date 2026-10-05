import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ingestion.dart';

enum AdminActionKind {
  saved,
  ran,
  backfillQueued,
  uploaded,
  categoryRunQueued,
  sourceCreated,
  sourceUpdated,
}

class AdminSchedulesState extends Equatable {
  const AdminSchedulesState({
    this.items = const DataState(),
    this.categories = const [],
    this.selectedCategory,
    this.busyCategories = const {},
    this.queuedSources = 0,
    this.busySourceIds = const {},
    this.actionFailure,
    this.lastAction,
    this.queuedDays = 0,
    this.actionSeq = 0,
  });

  final DataState<List<IngestionScheduleItem>> items;

  /// Every active category (also those with no source yet, so one can be
  /// added). Empty until loaded; the page then falls back to the categories
  /// found on the items.
  final List<AdminCategory> categories;

  /// Filter chip; null = all categories.
  final String? selectedCategory;

  /// Categories with a "Run all" in flight.
  final Set<String> busyCategories;

  /// Sources queued by the last "Run all", for its confirmation message.
  final int queuedSources;

  /// Sources with a save or run in flight; their buttons are disabled.
  final Set<String> busySourceIds;
  final Failure? actionFailure;
  final AdminActionKind? lastAction;

  /// Days queued by the last backfill, for its confirmation message.
  final int queuedDays;

  /// Bumps on every action result so the page shows each snackbar once.
  final int actionSeq;

  /// Categories to show as chips/sections, in display order: the loaded list,
  /// plus any category that only appears on a source.
  List<AdminCategory> get visibleCategories {
    final byCode = {for (final c in categories) c.code: c};
    final sorted = [
      ...?items.data,
    ]..sort((a, b) => a.categoryDisplayOrder.compareTo(b.categoryDisplayOrder));
    for (final item in sorted) {
      byCode.putIfAbsent(
        item.categoryCode,
        () => AdminCategory(code: item.categoryCode, name: item.categoryName),
      );
    }
    return byCode.values.toList();
  }

  /// Sources grouped by category, filtered by [selectedCategory]. Categories
  /// with no source are kept so their section can offer "Add source".
  List<(AdminCategory, List<IngestionScheduleItem>)> get sections => [
    for (final category in visibleCategories)
      if (selectedCategory == null || selectedCategory == category.code)
        (
          category,
          [
            for (final item in items.data ?? const <IngestionScheduleItem>[])
              if (item.categoryCode == category.code) item,
          ],
        ),
  ];

  AdminSchedulesState copyWith({
    DataState<List<IngestionScheduleItem>>? items,
    List<AdminCategory>? categories,
    String? Function()? selectedCategory,
    Set<String>? busyCategories,
    int? queuedSources,
    Set<String>? busySourceIds,
    Failure? actionFailure,
    AdminActionKind? lastAction,
    int? queuedDays,
    bool bumpSeq = false,
  }) => AdminSchedulesState(
    items: items ?? this.items,
    categories: categories ?? this.categories,
    selectedCategory: selectedCategory == null
        ? this.selectedCategory
        : selectedCategory(),
    busyCategories: busyCategories ?? this.busyCategories,
    queuedSources: queuedSources ?? this.queuedSources,
    busySourceIds: busySourceIds ?? this.busySourceIds,
    actionFailure: actionFailure,
    lastAction: lastAction,
    queuedDays: queuedDays ?? this.queuedDays,
    actionSeq: bumpSeq ? actionSeq + 1 : actionSeq,
  );

  @override
  List<Object?> get props => [
    items,
    categories,
    selectedCategory,
    busyCategories,
    queuedSources,
    busySourceIds,
    actionFailure,
    lastAction,
    queuedDays,
    actionSeq,
  ];
}

/// Price sources by category: schedules (edit, enable/disable, "Run now"),
/// per-category "Run all", add/edit source, backfill and CSV upload.
class AdminSchedulesCubit extends Cubit<AdminSchedulesState> {
  AdminSchedulesCubit(this._repository) : super(const AdminSchedulesState());

  final AdminIngestionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(items: DataState.loading(data: state.items.data)));
    final (schedules, categories) = await (
      _repository.getSchedules(),
      _repository.getCategories(),
    ).wait;
    if (isClosed) return;
    emit(
      state.copyWith(
        items: _merge(schedules),
        // Chips still work from the items when the category list fails.
        categories: switch (categories) {
          Ok(:final value) => value,
          Err() => null,
        },
      ),
    );
  }

  void selectCategory(String? categoryCode) =>
      emit(state.copyWith(selectedCategory: () => categoryCode));

  /// Queues every active source of the category; runs finish in the
  /// background, so pull to refresh shows each source's job as it completes.
  Future<void> runCategory(String categoryCode) async {
    if (state.busyCategories.contains(categoryCode)) return;
    emit(
      state.copyWith(busyCategories: {...state.busyCategories, categoryCode}),
    );

    final result = await _repository.runCategory(categoryCode);
    if (isClosed) return;

    emit(
      state.copyWith(
        busyCategories: {...state.busyCategories}..remove(categoryCode),
        actionFailure: switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
        lastAction: result is Ok ? AdminActionKind.categoryRunQueued : null,
        queuedSources: switch (result) {
          Ok(:final value) => value,
          Err() => 0,
        },
        bumpSeq: true,
      ),
    );
  }

  /// Returns true on success so the form can close; on failure the form stays
  /// open with the admin's input and the error shows as a snackbar.
  Future<bool> createSource(PriceSourceInput input) => _sourceAction(
    AdminActionKind.sourceCreated,
    () => _repository.createSource(input),
  );

  Future<bool> updateSource(String sourceId, PriceSourceInput input) =>
      _sourceAction(
        AdminActionKind.sourceUpdated,
        () => _repository.updateSource(sourceId, input),
      );

  Future<bool> _sourceAction(
    AdminActionKind kind,
    Future<Result<void>> Function() call,
  ) async {
    final result = await call();
    if (isClosed) return false;
    final reloaded = result is Ok ? await _repository.getSchedules() : null;
    if (isClosed) return false;
    emit(
      state.copyWith(
        items: reloaded == null ? null : _merge(reloaded),
        actionFailure: switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
        lastAction: result is Ok ? kind : null,
        bumpSeq: true,
      ),
    );
    return result is Ok;
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

  /// Imports a CSV; the import runs inside the request, so the list is
  /// reloaded afterwards to show the upload as the last run.
  Future<void> uploadCsv(String sourceId, String fileName, List<int> bytes) =>
      _act(
        sourceId,
        AdminActionKind.uploaded,
        () => _repository.uploadCsv(sourceId, fileName, bytes),
      );

  /// Queues past days; the runs finish in the background, so the list is not
  /// reloaded here — pull to refresh shows each day's job as it completes.
  Future<void> backfill(String sourceId, DateTime from, DateTime to) async {
    if (state.busySourceIds.contains(sourceId)) return;
    emit(state.copyWith(busySourceIds: {...state.busySourceIds, sourceId}));

    final result = await _repository.backfill(sourceId, from, to);
    if (isClosed) return;

    emit(
      state.copyWith(
        busySourceIds: {...state.busySourceIds}..remove(sourceId),
        actionFailure: switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        },
        lastAction: result is Ok ? AdminActionKind.backfillQueued : null,
        queuedDays: switch (result) {
          Ok(:final value) => value,
          Err() => 0,
        },
        bumpSeq: true,
      ),
    );
  }

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
