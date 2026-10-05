import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/json.dart';
import '../domain/weather.dart';
import 'weather_remote_data_source.dart';

@LazySingleton(as: WeatherRepository)
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._remote, this._cache);

  /// IMD issues one forecast a day; an hour-old copy is as good as a new one.
  static const _ttl = Duration(hours: 1);

  final WeatherRemoteDataSource _remote;
  final ResponseCache _cache;

  String _key(String stationId) => 'weather.forecast.$stationId';

  @override
  Future<Result<SevenDayForecast>> getForecast(String stationId) =>
      runCachedApiCall(
        cache: _cache,
        key: _key(stationId),
        fetch: () => _remote.forecast(stationId),
        parse: _parse,
      );

  @override
  Stream<Result<SevenDayForecast>> watchForecast(String stationId) =>
      watchCachedApiCall(
        cache: _cache,
        key: _key(stationId),
        ttl: _ttl,
        fetch: () => _remote.forecast(stationId),
        parse: _parse,
      );

  static SevenDayForecast _parse(Object json) {
    final m = json as Map<String, dynamic>;
    return SevenDayForecast(
      stationId: m.str('stationId'),
      stationName: m.str('stationName'),
      issuedAt: m.date('issuedAt'),
      days: m.list(
        'days',
        (d) => DailyForecast(
          date: DateTime.parse(d.str('date')),
          minTempC: d.number('minTempC'),
          maxTempC: d.number('maxTempC'),
          condition:
              WeatherCondition.values.asNameMap()[d.str('condition')] ??
              WeatherCondition.cloudy,
          rainChancePercent: d.integer('rainChancePercent'),
          humidityPercent: d.integer('humidityPercent'),
          windKmph: d.number('windKmph'),
        ),
      ),
    );
  }
}
