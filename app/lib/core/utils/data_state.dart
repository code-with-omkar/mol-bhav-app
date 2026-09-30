import 'package:equatable/equatable.dart';

import '../error/failure.dart';
import '../error/result.dart';
import 'statuses.dart';

/// Status + data + failure for a screen that fetches one thing.
class DataState<T> extends Equatable {
  const DataState({this.status = LoadStatus.initial, this.data, this.failure});

  const DataState.loading({this.data})
    : status = LoadStatus.loading,
      failure = null;

  const DataState.ready(T this.data)
    : status = LoadStatus.ready,
      failure = null;

  factory DataState.fromResult(Result<T> result) => result.fold(
    (failure) => DataState(status: LoadStatus.failure, failure: failure),
    (data) => DataState(status: LoadStatus.ready, data: data),
  );

  final LoadStatus status;
  final T? data;
  final Failure? failure;

  bool get isLoading =>
      status == LoadStatus.initial || status == LoadStatus.loading;

  /// Showing data while a newer copy loads.
  bool get isRevalidating => status == LoadStatus.loading && data != null;

  @override
  List<Object?> get props => [status, data, failure];
}

/// Folds a stale-while-revalidate stream into screen states: `loading` (with
/// the newest data so far) while values arrive, then `ready`. A failure keeps
/// the data already shown.
Stream<DataState<T>> revalidate<T>(
  Stream<Result<T>> source, {
  T? current,
}) async* {
  var data = current;
  Failure? failure;
  yield DataState.loading(data: data);
  await for (final result in source) {
    switch (result) {
      case Ok<T>(:final value):
        data = value;
        failure = null;
        yield DataState.loading(data: data);
      case Err<T>(failure: final f):
        failure = f;
    }
  }
  yield failure == null
      ? DataState(status: LoadStatus.ready, data: data)
      : DataState(status: LoadStatus.failure, data: data, failure: failure);
}
