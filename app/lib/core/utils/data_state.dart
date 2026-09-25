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

  @override
  List<Object?> get props => [status, data, failure];
}
