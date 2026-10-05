import 'package:equatable/equatable.dart';

<<<<<<< HEAD
class CurrentWeather extends Equatable {
  final double temperature;
  final int weatherCode;
  final String description;
  final int humidity;
  final double windSpeed;

=======
/// Current weather data fetched from Open-Meteo API.
/// Represents temperature, weather condition, and related metrics.
class CurrentWeather extends Equatable {
>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
  const CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

<<<<<<< HEAD
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    return CurrentWeather(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      description: _weatherCodeToDescription(
        (current['weather_code'] as num?)?.toInt() ?? 0,
      ),
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static String _weatherCodeToDescription(int code) {
    const weatherCodes = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Foggy',
      51: 'Light drizzle',
      53: 'Drizzle',
      55: 'Heavy drizzle',
      61: 'Light rain',
      63: 'Rain',
      65: 'Heavy rain',
      71: 'Light snow',
      73: 'Snow',
      75: 'Heavy snow',
      77: 'Snow grains',
      80: 'Light showers',
      81: 'Showers',
      82: 'Heavy showers',
      85: 'Light snow showers',
      86: 'Snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with hail',
      99: 'Thunderstorm with hail',
    };
    return weatherCodes[code] ?? 'Unknown';
  }

  static String weatherCodeToEmoji(int code) {
    if (code == 0 || code == 1) return '☀️';
    if (code == 2) return '⛅';
    if (code == 3 || code == 45 || code == 48) return '☁️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 86) return '❄️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code >= 85 && code <= 86) return '❄️';
    if (code >= 95 && code <= 99) return '⛈️';
    return '🌡️';
=======
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
>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
  }

  @override
  List<Object?> get props => [temperature, weatherCode, description, humidity, windSpeed];
}

<<<<<<< HEAD
class LocationCoords extends Equatable {
  final double latitude;
  final double longitude;

=======
/// GPS coordinates for weather location.
class LocationCoords extends Equatable {
>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
  const LocationCoords({
    required this.latitude,
    required this.longitude,
  });

<<<<<<< HEAD
=======
  final double latitude;
  final double longitude;

>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
  @override
  List<Object?> get props => [latitude, longitude];
}
