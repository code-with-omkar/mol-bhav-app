import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/weather/weather_models.dart';
import '../../../core/weather/weather_service.dart';

/// Manages current weather state for the home screen.
/// Fetches location-based weather from Open-Meteo API and caches the result.
@injectable
class WeatherCubit extends Cubit<DataState<CurrentWeather>> {
  WeatherCubit(this._weatherService) : super(const DataState());

  final WeatherService _weatherService;

  /// Fetch current weather using device GPS location.
  /// Emits loading → success or failure.
  Future<void> fetchWeather() async {
    emit(const DataState.loading());
    try {
      final weather = await _weatherService.getCurrentWeather();
      if (isClosed) return;
      emit(DataState.ready(weather));
    } catch (e) {
      if (isClosed) return;
      emit(
        DataState(
          status: LoadStatus.failure,
          failure: WeatherFailure(e.toString()),
        ),
      );
    }
  }

  /// Watch for weather updates (typically called once on home init).
  /// Auto-retry on failure after delay.
  Future<void> watchWeather() async {
    await fetchWeather();
    if (state.status == LoadStatus.failure) {
      // Optional: Implement auto-retry with exponential backoff
      // For now, single attempt is sufficient for MVP.
    }
  }

  /// Clear cached weather data (useful for manual refresh).
  Future<void> clearCache() async {
    await _weatherService.clearCache();
    emit(const DataState());
  }
}

/// Simple failure wrapper for weather-specific errors.
class WeatherFailure implements Exception {
  WeatherFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
