import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'weather_models.dart';

class WeatherService {
  static const String _locationLatKey = 'weather_location_lat';
  static const String _locationLngKey = 'weather_location_lng';
  static const String _weatherCacheKey = 'weather_cache';
  static const String _weatherCacheTimeKey = 'weather_cache_time';
  static const Duration _cacheTTL = Duration(hours: 4);

  final SharedPreferences _prefs;

  WeatherService(this._prefs);

  /// Get current weather: fetch from cache or API
  Future<CurrentWeather?> getCurrentWeather() async {
    try {
      // Check cache
      final cached = _getCachedWeather();
      if (cached != null) return cached;

      // Get location
      final coords = await _getOrFetchLocation();
      if (coords == null) return null;

      // Fetch from Open-Meteo
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=${coords.latitude}&longitude=${coords.longitude}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('timeout', 408),
      );

      if (response.statusCode == 200) {
        final weather = CurrentWeather.fromJson(jsonDecode(response.body));
        _cacheWeather(weather);
        return weather;
      }
    } catch (e) {
      print('WeatherService error: $e');
    }
    return null;
  }

  /// Request location permission & get coords
  Future<LocationCoords?> _getOrFetchLocation() async {
    // Check cache first
    final cachedLat = _prefs.getDouble(_locationLatKey);
    final cachedLng = _prefs.getDouble(_locationLngKey);
    if (cachedLat != null && cachedLng != null) {
      return LocationCoords(latitude: cachedLat, longitude: cachedLng);
    }

    // Request permission
    final status = await Permission.location.request();

    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );

        // Cache for future use
        await _prefs.setDouble(_locationLatKey, position.latitude);
        await _prefs.setDouble(_locationLngKey, position.longitude);

        return LocationCoords(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (e) {
        print('Geolocator error: $e');
      }
    }

    return null;
  }

  CurrentWeather? _getCachedWeather() {
    final cachedJson = _prefs.getString(_weatherCacheKey);
    final cachedTime = _prefs.getInt(_weatherCacheTimeKey);

    if (cachedJson != null && cachedTime != null) {
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
      if (age < _cacheTTL.inMilliseconds) {
        try {
          return CurrentWeather.fromJson(jsonDecode(cachedJson));
        } catch (e) {
          print('Cache decode error: $e');
        }
      }
    }
    return null;
  }

  void _cacheWeather(CurrentWeather weather) {
    try {
      final json = {
        'current': {
          'temperature_2m': weather.temperature,
          'weather_code': weather.weatherCode,
          'relative_humidity_2m': weather.humidity,
          'wind_speed_10m': weather.windSpeed,
        }
      };
      _prefs.setString(_weatherCacheKey, jsonEncode(json));
      _prefs.setInt(_weatherCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Cache write error: $e');
    }
  }

  /// Clear cached location & weather
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_locationLatKey),
      _prefs.remove(_locationLngKey),
      _prefs.remove(_weatherCacheKey),
      _prefs.remove(_weatherCacheTimeKey),
    ]);
  }
}
