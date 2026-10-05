<<<<<<< HEAD
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
=======
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_models.dart';

/// Service to fetch and cache weather data from Open-Meteo API.
/// Uses device GPS location and stores results in SharedPreferences with 4-hour TTL.
@injectable
class WeatherService {
  WeatherService(this._prefs);

  final SharedPreferences _prefs;

  static const _locationLatKey = 'weather_location_lat';
  static const _locationLngKey = 'weather_location_lng';
  static const _weatherCacheKey = 'weather_cache';
  static const _weatherCacheTimeKey = 'weather_cache_time';
  static const _weatherCacheTtlHours = 4;
  static const _apiBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _httpTimeout = Duration(seconds: 10);
  static const _locationTimeout = Duration(seconds: 10);

  /// Fetch current weather using device GPS location.
  /// Returns cached result if available and within TTL.
  /// Requests location permission if not granted.
  ///
  /// Throws exception if location unavailable or API fails.
  Future<CurrentWeather> getCurrentWeather() async {
    // Check cache first
    final cached = _getCachedWeather();
    if (cached != null) {
      return cached;
    }

    // Get location (requests permission if needed)
    final location = await _getOrFetchLocation();

    // Fetch from API
    final weather = await _fetchWeatherFromApi(location);

    // Cache result
    _cacheWeather(weather);

    return weather;
  }

  /// Watch for weather updates and trigger initial fetch.
  Future<void> watchWeather() => getCurrentWeather();

  /// Clear all cached weather and location data.
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_weatherCacheKey),
      _prefs.remove(_weatherCacheTimeKey),
      _prefs.remove(_locationLatKey),
      _prefs.remove(_locationLngKey),
    ]);
  }

  /// Get cached weather if available and fresh (within TTL).
  CurrentWeather? _getCachedWeather() {
    final cached = _prefs.getString(_weatherCacheKey);
    final timestamp = _prefs.getInt(_weatherCacheTimeKey);

    if (cached == null || timestamp == null) {
      return null;
    }

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cacheTime);

    if (age.inHours < _weatherCacheTtlHours) {
      try {
        return CurrentWeather.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (e) {
        // Corrupt cache, ignore
        return null;
      }
    }

    return null;
  }

  /// Cache weather data with current timestamp.
  void _cacheWeather(CurrentWeather weather) {
    _prefs.setString(_weatherCacheKey, jsonEncode({
      'current': {
        'temperature_2m': weather.temperature,
        'weather_code': weather.weatherCode,
        'relative_humidity_2m': weather.humidity,
        'wind_speed_10m': weather.windSpeed,
      }
    }));
    _prefs.setInt(_weatherCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached location or request permission + fetch via Geolocator.
  Future<LocationCoords> _getOrFetchLocation() async {
    // Try cached location first
    final cachedLat = _prefs.getDouble(_locationLatKey);
    final cachedLng = _prefs.getDouble(_locationLngKey);

>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
    if (cachedLat != null && cachedLng != null) {
      return LocationCoords(latitude: cachedLat, longitude: cachedLng);
    }

<<<<<<< HEAD
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
=======
    // Request location permission
    final permission = await _requestLocationPermission();
    if (!permission) {
      throw Exception('Location permission denied');
    }

    // Fetch current position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // Lower accuracy → faster, less battery
        timeLimit: _locationTimeout,
      ),
    );

    // Cache location
    await Future.wait([
      _prefs.setDouble(_locationLatKey, position.latitude),
      _prefs.setDouble(_locationLngKey, position.longitude),
    ]);

    return LocationCoords(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Request location permission via permission_handler package.
  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Fetch weather data from Open-Meteo API.
  ///
  /// Request: /v1/forecast?latitude=...&longitude=...&current=temperature_2m,...&timezone=auto
  /// Response: { "current": { "temperature_2m": 25.5, ... } }
  Future<CurrentWeather> _fetchWeatherFromApi(LocationCoords location) async {
    final url = Uri.parse(_apiBaseUrl).replace(
      queryParameters: {
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'timezone': 'auto',
      },
    );

    final response = await http
        .get(url)
        .timeout(_httpTimeout);

    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CurrentWeather.fromJson(json);
>>>>>>> 3c0db1a53330c423562aed2a14ec726797682e4f
  }
}
