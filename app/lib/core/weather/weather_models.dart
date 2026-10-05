import 'package:equatable/equatable.dart';

class CurrentWeather extends Equatable {
  final double temperature;
  final int weatherCode;
  final String description;
  final int humidity;
  final double windSpeed;

  const CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });

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
  }

  @override
  List<Object?> get props => [temperature, weatherCode, description, humidity, windSpeed];
}

class LocationCoords extends Equatable {
  final double latitude;
  final double longitude;

  const LocationCoords({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
