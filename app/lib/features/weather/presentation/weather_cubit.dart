import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/permissions/imd_station_lookup.dart';
import '../../../core/permissions/location_permission_handler.dart';
import '../../../core/utils/data_state.dart';
import '../domain/weather.dart';

/// Why there is no forecast to show.
enum WeatherLocationStatus {
  /// Nothing tried yet.
  unknown,

  /// No cached station and permission not granted: ask the user.
  needsPermission,
  resolving,
  resolved,
  denied,
  deniedForever,
  serviceOff,
  outOfCoverage,
  unavailable,
}

class WeatherState extends Equatable {
  const WeatherState({
    this.location = WeatherLocationStatus.unknown,
    this.station,
    this.forecast = const DataState(),
    this.selectedDay = 0,
  });

  final WeatherLocationStatus location;
  final ImdStation? station;
  final DataState<SevenDayForecast> forecast;

  /// Index into the forecast's days shown on the weather tab.
  final int selectedDay;

  DailyForecast? get today => forecast.data?.today;

  WeatherState copyWith({
    WeatherLocationStatus? location,
    ImdStation? station,
    DataState<SevenDayForecast>? forecast,
    int? selectedDay,
  }) => WeatherState(
    location: location ?? this.location,
    station: station ?? this.station,
    forecast: forecast ?? this.forecast,
    selectedDay: selectedDay ?? this.selectedDay,
  );

  @override
  List<Object?> get props => [location, station, forecast, selectedDay];
}

/// App-wide so the home header and the weather tab share one forecast.
@lazySingleton
class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit(this._repository, this._location) : super(const WeatherState());

  final WeatherRepository _repository;
  final LocationPermissionHandler _location;

  StreamSubscription<DataState<SevenDayForecast>>? _sub;

  /// Home load: a cached station goes straight to the forecast; without one
  /// the screen is asked to show the permission dialog.
  Future<void> fetchForecast() async {
    if (state.forecast.data != null ||
        state.location == WeatherLocationStatus.resolving) {
      return;
    }
    final station = _location.cachedStation;
    if (station != null) return _load(station);
    if (await _location.canPrompt) {
      emit(state.copyWith(location: WeatherLocationStatus.needsPermission));
    } else {
      await requestLocation();
    }
  }

  /// The user agreed to share their location (or retries after settings).
  Future<void> requestLocation() async {
    emit(state.copyWith(location: WeatherLocationStatus.resolving));
    final outcome = await _location.resolve();
    if (isClosed) return;
    switch (outcome) {
      case LocationResolved(:final station):
        await _load(station);
      case LocationDenied():
        emit(state.copyWith(location: WeatherLocationStatus.denied));
      case LocationDeniedForever():
        emit(state.copyWith(location: WeatherLocationStatus.deniedForever));
      case LocationServiceOff():
        emit(state.copyWith(location: WeatherLocationStatus.serviceOff));
      case LocationOutOfCoverage():
        emit(state.copyWith(location: WeatherLocationStatus.outOfCoverage));
      case LocationUnavailable():
        emit(state.copyWith(location: WeatherLocationStatus.unavailable));
    }
  }

  /// Pull-to-refresh / retry. Re-resolves the location when it is missing.
  Future<void> refreshWeather() async {
    final station = state.station ?? _location.cachedStation;
    if (station == null) {
      return state.location == WeatherLocationStatus.needsPermission
          ? null
          : requestLocation();
    }
    return _load(station);
  }

  void selectDay(int index) {
    final days = state.forecast.data?.days.length ?? 0;
    if (index >= 0 && index < days) emit(state.copyWith(selectedDay: index));
  }

  Future<bool> openSettings() =>
      state.location == WeatherLocationStatus.serviceOff
      ? _location.openLocationSettings()
      : _location.openAppSettings();

  Future<void> _load(ImdStation station) async {
    await _sub?.cancel();
    emit(
      state.copyWith(
        location: WeatherLocationStatus.resolved,
        station: station,
        forecast: DataState.loading(data: state.forecast.data),
      ),
    );
    final done = Completer<void>();
    _sub =
        revalidate(
          _repository.watchForecast(station.id),
          current: state.forecast.data,
        ).listen((forecast) {
          if (isClosed) return;
          final days = forecast.data?.days.length ?? 0;
          emit(
            state.copyWith(
              forecast: forecast,
              selectedDay: state.selectedDay < days ? state.selectedDay : 0,
            ),
          );
        }, onDone: done.complete);
    await done.future;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
