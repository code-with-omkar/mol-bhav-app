import 'failure.dart';

/// Outcome of a repository call: [Ok] or [Err].
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onError, R Function(T value) onOk) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onError(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
