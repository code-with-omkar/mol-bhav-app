import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_jobs.dart';

class PullJobState extends Equatable {
  const PullJobState({
    this.job = const DataState(),
    this.errors = const [],
    this.hasMoreErrors = false,
    this.loadingErrors = false,
    this.errorsFailure,
  });

  final DataState<AdminJob> job;

  /// The rows this run could not use, oldest first.
  final List<AdminJobError> errors;
  final bool hasMoreErrors;
  final bool loadingErrors;

  /// The error rows could not be loaded (the run itself did).
  final Failure? errorsFailure;

  PullJobState copyWith({
    DataState<AdminJob>? job,
    List<AdminJobError>? errors,
    bool? hasMoreErrors,
    bool? loadingErrors,
    Failure? Function()? errorsFailure,
  }) => PullJobState(
    job: job ?? this.job,
    errors: errors ?? this.errors,
    hasMoreErrors: hasMoreErrors ?? this.hasMoreErrors,
    loadingErrors: loadingErrors ?? this.loadingErrors,
    errorsFailure: errorsFailure != null ? errorsFailure() : this.errorsFailure,
  );

  @override
  List<Object?> get props => [
    job,
    errors,
    hasMoreErrors,
    loadingErrors,
    errorsFailure,
  ];
}

/// One run in full: its counts and, a page at a time, the rows that failed.
@injectable
class PullJobCubit extends Cubit<PullJobState> {
  PullJobCubit(this._repository) : super(const PullJobState());

  static const pageSize = 20;

  final AdminJobsRepository _repository;
  int _page = 1;

  Future<void> load(String jobId) async {
    emit(state.copyWith(job: DataState.loading(data: state.job.data)));
    final result = await _repository.getJob(jobId);
    if (isClosed) return;
    emit(state.copyWith(job: DataState.fromResult(result)));
    if (result case Ok<AdminJob>(:final value) when value.failed > 0) {
      await _loadErrors(jobId, reset: true);
    }
  }

  Future<void> loadMoreErrors(String jobId) {
    if (!state.hasMoreErrors || state.loadingErrors) return Future.value();
    return _loadErrors(jobId, reset: false);
  }

  Future<void> _loadErrors(String jobId, {required bool reset}) async {
    if (reset) _page = 0;
    emit(state.copyWith(loadingErrors: true, errorsFailure: () => null));
    final result = await _repository.getErrors(
      jobId,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminJobError>>(:final value):
        _page++;
        emit(
          state.copyWith(
            errors: reset ? value : [...state.errors, ...value],
            hasMoreErrors: value.length == pageSize,
            loadingErrors: false,
          ),
        );
      case Err<List<AdminJobError>>(:final failure):
        emit(
          state.copyWith(loadingErrors: false, errorsFailure: () => failure),
        );
    }
  }
}
