import 'dart:io';

import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../error/result.dart';

/// Maps a feature-specific response to a [Failure], or `null` to fall back to
/// the default mapping.
typedef FailureMapper = Failure? Function(DioException error);

/// Runs [call] and converts thrown errors into a [Result].
Future<Result<T>> runApiCall<T>(
  Future<T> Function() call, {
  FailureMapper? mapError,
}) async {
  try {
    return Ok(await call());
  } on DioException catch (e) {
    return Err(mapError?.call(e) ?? mapDioException(e));
  } on FormatException {
    return const Err(UnexpectedFailure());
  } on TypeError {
    return const Err(UnexpectedFailure());
  }
}

Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 401) return const UnauthorizedFailure();
      return ServerFailure(
        statusCode: status,
        message: serverMessage(e.response?.data),
      );
    case DioExceptionType.unknown:
      if (e.error is SocketException) return const NetworkFailure();
      return const UnexpectedFailure();
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
      return const UnexpectedFailure();
  }
}

/// Reads the `message` (or RFC 7807 `detail`/`title`) from an error body.
String? serverMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    for (final key in const ['message', 'detail', 'title']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
  }
  return null;
}
