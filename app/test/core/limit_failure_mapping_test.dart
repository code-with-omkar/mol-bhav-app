import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/network/api_call.dart';

DioException _forbidden(Object? data) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 403, data: data),
  );
}

void main() {
  group('free-tier limit errors', () {
    test('map each limit code to its feature', () {
      const cases = {
        'Entitlement.WatchlistLimitReached': LimitedFeature.watchlist,
        'Entitlement.AlertRuleLimitReached': LimitedFeature.alertRules,
        'Report.ProRequired': LimitedFeature.proReport,
      };
      for (final MapEntry(key: code, value: feature) in cases.entries) {
        final failure = mapDioException(
          _forbidden({'errorCode': code, 'detail': 'Limit'}),
        );
        expect(failure, LimitReachedFailure(feature, message: 'Limit'));
      }
    });

    test('leave other 403s as ServerFailure', () {
      final failure = mapDioException(
        _forbidden({'errorCode': 'AdUnlock.LimitReached', 'detail': 'No'}),
      );
      expect(failure, const ServerFailure(statusCode: 403, message: 'No'));
    });

    test('ignore a limit code on a non-403 response', () {
      final options = RequestOptions(path: '/x');
      final failure = mapDioException(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 409,
            data: {'errorCode': 'Report.ProRequired'},
          ),
        ),
      );
      expect(failure, isA<ServerFailure>());
    });
  });
}
