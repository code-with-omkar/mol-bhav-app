import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

/// Raw forecast JSON for one station:
///
/// ```json
/// { "stationId": "pune", "stationName": "Pune", "issuedAt": "2026-10-04T05:30:00Z",
///   "days": [ { "date": "2026-10-04", "minTempC": 21, "maxTempC": 31,
///               "condition": "rain", "rainChancePercent": 70,
///               "humidityPercent": 80, "windKmph": 12 } ] }
/// ```
///
/// `condition` is one of `clear`, `partlyCloudy`, `cloudy`, `rain`,
/// `thunderstorm`. Kept raw so the response cache stores the API body as is.
abstract interface class WeatherRemoteDataSource {
  Future<Map<String, dynamic>> forecast(String stationId);
}

/// `GET /weather/forecast?stationId=`
class DioWeatherRemoteDataSource implements WeatherRemoteDataSource {
  DioWeatherRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> forecast(String stationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/weather/forecast',
      queryParameters: {'stationId': stationId},
    );
    return response.data!;
  }
}

/// Deterministic forecast for development while the weather endpoint does not
/// exist. Enabled by `--dart-define=WEATHER_STUB=true` (the default for now).
class StubWeatherRemoteDataSource implements WeatherRemoteDataSource {
  static const _conditions = [
    'clear',
    'partlyCloudy',
    'cloudy',
    'rain',
    'thunderstorm',
  ];

  @override
  Future<Map<String, dynamic>> forecast(String stationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seed = stationId.codeUnits.fold<int>(0, (a, b) => a + b);
    final random = math.Random(seed + today.day);
    return {
      'stationId': stationId,
      'stationName': _title(stationId),
      'issuedAt': now.toUtc().toIso8601String(),
      'days': [
        for (var i = 0; i < 7; i++)
          () {
            final condition = _conditions[(seed + today.day + i * 2) % 5];
            final min = 18 + random.nextInt(8);
            final wet = condition == 'rain' || condition == 'thunderstorm';
            return {
              'date': today
                  .add(Duration(days: i))
                  .toIso8601String()
                  .substring(0, 10),
              'minTempC': min,
              'maxTempC': min + 6 + random.nextInt(6),
              'condition': condition,
              'rainChancePercent': wet
                  ? 60 + random.nextInt(35)
                  : random.nextInt(30),
              'humidityPercent': wet
                  ? 75 + random.nextInt(20)
                  : 40 + random.nextInt(30),
              'windKmph': 6 + random.nextInt(18),
            };
          }(),
      ],
    };
  }

  static String _title(String id) => id
      .split('-')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

abstract final class WeatherConfig {
  /// Stays on until the backend serves `/weather/forecast`.
  static const useStub = bool.fromEnvironment(
    'WEATHER_STUB',
    defaultValue: true,
  );
}

@module
abstract class WeatherModule {
  @lazySingleton
  WeatherRemoteDataSource weatherRemoteDataSource(Dio dio) =>
      WeatherConfig.useStub
      ? StubWeatherRemoteDataSource()
      : DioWeatherRemoteDataSource(dio);
}
