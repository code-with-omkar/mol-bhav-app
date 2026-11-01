import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Home header shows the moving weather scene (clouds, rain,
/// sun glow). On by default; the weather button and the forecast stay either
/// way. Kept on this device only.
@lazySingleton
class HomeWeatherAnimationCubit extends Cubit<bool> {
  HomeWeatherAnimationCubit(this._prefs) : super(_prefs.getBool(key) ?? true);

  final SharedPreferences _prefs;

  static const key = 'home.weatherAnimation';

  Future<void> set(bool enabled) async {
    if (enabled == state) return;
    emit(enabled);
    await _prefs.setBool(key, enabled);
  }
}
