import 'package:equatable/equatable.dart';

/// Current weather data fetched from Open-Meteo API.
/// Represents temperature, weather condition, and related metrics.
class CurrentWeather extends Equatable {
  const CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

  /// Temperature in Celsius.
  final double temperature;

  /// WMO Weather Code (0-99).
  /// See: https://www.weather-gov.uk/guide/codes
  final int weatherCode;

  /// Human-readable weather description (e.g., "Partly cloudy").
  final String description;

  /// Relative humidity percentage (0-100).
  final int humidity;

  /// Wind speed in m/s at 10m height.
  final double windSpeed;

  /// Factory constructor parsing Open-Meteo API JSON response.
  /// Expected structure:
  /// {
  ///   "current": {
  ///     "temperature_2m": 25.5,
  ///     "weather_code": 2,
  ///     "relative_humidity_2m": 65,
  ///     "wind_speed_10m": 3.2
  ///   }
  /// }
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw FormatException('Missing "current" field in weather response');
    }

    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
    final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;

    return CurrentWeather(
      temperature: temp,
      weatherCode: code,
      description: _weatherCodeToDescription(code),
      humidity: humidity,
      windSpeed: windSpeed,
    );
  }

  /// Maps WMO weather code to human-readable description.
  /// See: https://www.weather-gov.uk/guide/codes
  static String _weatherCodeToDescription(int code) {
    return switch (code) {
      0 => 'Clear',
      1 || 2 => 'Mainly clear',
      3 => 'Overcast',
      45 || 48 => 'Foggy',
      51 || 53 || 55 => 'Drizzle',
      61 || 63 || 65 => 'Rain',
      71 || 73 || 75 => 'Snow',
      77 => 'Snow grains',
      80 || 82 || 86 => 'Rain showers',
      81 => 'Rain showers moderate',
      83 => 'Rain showers violent',
      85 => 'Snow showers',
      95 || 96 || 99 => 'Thunderstorm',
      _ => 'Unknown',
    };
  }

  /// Maps WMO weather code to emoji representation.
  static String weatherCodeToEmoji(int code) {
    return switch (code) {
      0 => '☀️',
      1 || 2 => '🌤️',
      3 => '☁️',
      45 || 48 => '🌫️',
      51 || 53 || 55 => '🌦️',
      61 || 63 || 65 => '🌧️',
      71 || 73 || 75 => '❄️',
      77 => '❄️',
      80 || 82 => '🌧️',
      81 || 83 => '⛈️',
      85 || 86 => '🌨️',
      95 || 96 || 99 => '⛈️',
      _ => '🌡️',
    };
  }

  @override
  List<Object?> get props => [temperature, weatherCode, description, humidity, windSpeed];
}

/// GPS coordinates for weather location.
class LocationCoords extends Equatable {
  const LocationCoords({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}
