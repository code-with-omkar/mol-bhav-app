import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_jobs.dart';

class PullHistoryState extends Equatable {
  const PullHistoryState({
    this.status = LoadStatus.initial,
    this.jobs = const [],
    this.filter = JobListFilter.all,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  final LoadStatus status;
  final List<AdminJob> jobs;
  final JobListFilter filter;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  PullHistoryState copyWith({
    LoadStatus? status,
    List<AdminJob>? jobs,
    JobListFilter? filter,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => PullHistoryState(
    status: status ?? this.status,
    jobs: jobs ?? this.jobs,
    filter: filter ?? this.filter,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    jobs,
    filter,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// Recent price-feed runs, newest first, filtered by outcome, with "load more".
@injectable
class PullHistoryCubit extends Cubit<PullHistoryState> {
  PullHistoryCubit(this._repository) : super(const PullHistoryState());

  static const pageSize = 20;

  final AdminJobsRepository _repository;
  int _page = 1;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getJobs(
      filter: state.filter,
      page: 1,
      pageSize: pageSize,
    );
    // A newer filter has its own request in flight.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminJob>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            jobs: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminJob>>(:final failure):
        emit(
          state.copyWith(status: LoadStatus.failure, failure: () => failure),
        );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != LoadStatus.ready) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    final result = await _repository.getJobs(
      filter: state.filter,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminJob>>(:final value):
        _page++;
        emit(
          state.copyWith(
            jobs: [...state.jobs, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminJob>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> setFilter(JobListFilter filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: filter));
    return load();
  }
}
