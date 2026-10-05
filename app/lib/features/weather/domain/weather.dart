import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

enum WeatherCondition { clear, partlyCloudy, cloudy, rain, thunderstorm }

/// Maps a WMO weather code (Open-Meteo) to the nearest [WeatherCondition].
WeatherCondition conditionFromWmoCode(int code) => switch (code) {
  0 => WeatherCondition.clear,
  1 || 2 => WeatherCondition.partlyCloudy,
  >= 95 => WeatherCondition.thunderstorm,
  >= 51 && <= 67 || >= 80 && <= 82 => WeatherCondition.rain,
  _ => WeatherCondition.cloudy,
};

/// One day of an IMD station forecast.
class DailyForecast extends Equatable {
  const DailyForecast({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.condition,
    required this.rainChancePercent,
    required this.humidityPercent,
    required this.windKmph,
  });

  final DateTime date;
  final num minTempC;
  final num maxTempC;
  final WeatherCondition condition;
  final int rainChancePercent;
  final int humidityPercent;
  final num windKmph;

  @override
  List<Object?> get props => [
    date,
    minTempC,
    maxTempC,
    condition,
    rainChancePercent,
    humidityPercent,
    windKmph,
  ];
}

/// Today plus the next six days for one IMD station.
class SevenDayForecast extends Equatable {
  const SevenDayForecast({
    required this.stationId,
    required this.stationName,
    required this.issuedAt,
    required this.days,
  });

  final String stationId;
  final String stationName;
  final DateTime issuedAt;

  /// Ordered by date; the first entry is today.
  final List<DailyForecast> days;

  DailyForecast? get today => days.firstOrNull;

  @override
  List<Object?> get props => [stationId, stationName, issuedAt, days];
}

abstract interface class WeatherRepository {
  Future<Result<SevenDayForecast>> getForecast(String stationId);

  /// Cached forecast first (when there is one), then the live one.
  Stream<Result<SevenDayForecast>> watchForecast(String stationId);
}
