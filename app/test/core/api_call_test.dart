import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/network/api_call.dart';

DioException _dio(
  DioExceptionType type, {
  int? status,
  Object? data,
  Object? error,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

Failure? _failureOf<T>(Result<T> result) =>
    result.fold((failure) => failure, (_) => null);

void main() {
  group('runApiCall', () {
    test('returns Ok with the value', () async {
      final result = await runApiCall(() async => 42);
      expect(result.fold((_) => null, (v) => v), 42);
    });

    test('maps timeouts and connection errors to NetworkFailure', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final result = await runApiCall<int>(() => throw _dio(type));
        expect(_failureOf(result), const NetworkFailure());
      }
    });

    test('maps a socket error to NetworkFailure', () async {
      final result = await runApiCall<int>(
        () => throw _dio(
          DioExceptionType.unknown,
          error: const SocketException('down'),
        ),
      );
      expect(_failureOf(result), const NetworkFailure());
    });

    test('maps 401 to UnauthorizedFailure', () async {
      final result = await runApiCall<int>(
        () => throw _dio(DioExceptionType.badResponse, status: 401),
      );
      expect(_failureOf(result), const UnauthorizedFailure());
    });

    test(
      'maps other statuses to ServerFailure with the server message',
      () async {
        final result = await runApiCall<int>(
          () => throw _dio(
            DioExceptionType.badResponse,
            status: 500,
            data: {'message': 'Down for maintenance'},
          ),
        );
        expect(
          _failureOf(result),
          const ServerFailure(statusCode: 500, message: 'Down for maintenance'),
        );
      },
    );

    test('lets a feature mapper override the default mapping', () async {
      final result = await runApiCall<int>(
        () => throw _dio(DioExceptionType.badResponse, status: 422),
        mapError: (_) => const NetworkFailure(),
      );
      expect(_failureOf(result), const NetworkFailure());
    });

    test('maps malformed payloads to UnexpectedFailure', () async {
      final result = await runApiCall<int>(
        () async => ({'a': 'b'} as dynamic)['a'] as int,
      );
      expect(_failureOf(result), const UnexpectedFailure());
    });
  });
}
