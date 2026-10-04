import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user agreed to ads based on their activity. Off until they turn
/// it on: under India's DPDP Act consent must be given freely and cannot be a
/// condition of using the app, so the default is non-personalised ads.
@lazySingleton
class AdPersonalisationCubit extends Cubit<bool> {
  AdPersonalisationCubit(this._prefs) : super(_prefs.getBool(_key) ?? false);

  final SharedPreferences _prefs;

  static const _key = 'ads.personalised';

  Future<void> set(bool personalised) async {
    emit(personalised);
    await _prefs.setBool(_key, personalised);
  }
}
