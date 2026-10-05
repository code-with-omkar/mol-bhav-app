import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'imd_station_lookup.dart';

/// Where the device last resolved to.
sealed class LocationOutcome {
  const LocationOutcome();
}

final class LocationResolved extends LocationOutcome {
  const LocationResolved(this.station);

  final ImdStation station;
}

/// Permission not asked yet, or denied this time (can be asked again).
final class LocationDenied extends LocationOutcome {
  const LocationDenied();
}

/// Denied with "don't ask again": only the system settings can change it.
final class LocationDeniedForever extends LocationOutcome {
  const LocationDeniedForever();
}

final class LocationServiceOff extends LocationOutcome {
  const LocationServiceOff();
}

/// The position was found but no IMD station is near enough.
final class LocationOutOfCoverage extends LocationOutcome {
  const LocationOutOfCoverage();
}

final class LocationUnavailable extends LocationOutcome {
  const LocationUnavailable();
}

/// Device GPS → nearest IMD station, remembered in SharedPreferences so the
/// permission is only asked on a cache miss.
@lazySingleton
class LocationPermissionHandler {
  LocationPermissionHandler(this._prefs);

  static const _stationKey = 'weather.station_id';

  final SharedPreferences _prefs;

  ImdStation? get cachedStation {
    final id = _prefs.getString(_stationKey);
    return id == null ? null : ImdStationLookup.byId(id);
  }

  Future<void> clearCache() => _prefs.remove(_stationKey);

  /// Whether the OS would show the permission prompt (never asked before).
  Future<bool> get canPrompt async =>
      await Geolocator.checkPermission() == LocationPermission.denied;

  /// Asks for permission when needed, reads a coarse position and caches the
  /// nearest station.
  Future<LocationOutcome> resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationDenied();
        case LocationPermission.deniedForever:
          return const LocationDeniedForever();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final station = ImdStationLookup.nearest(
        position.latitude,
        position.longitude,
      );
      if (station == null) return const LocationOutOfCoverage();
      await _prefs.setString(_stationKey, station.id);
      return LocationResolved(station);
    } on Exception {
      return const LocationUnavailable();
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
