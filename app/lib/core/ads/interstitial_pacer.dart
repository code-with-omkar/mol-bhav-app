import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps full-screen ads rare: at least [minGap] apart and at most [maxPerDay]
/// per calendar day. Persisted, so restarting the app doesn't reset it —
/// AdMob's interstitial policy forbids ads that overwhelm users.
@lazySingleton
class InterstitialPacer {
  InterstitialPacer(this._prefs) : _clock = DateTime.now;

  @visibleForTesting
  InterstitialPacer.withClock(this._prefs, this._clock);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const minGap = Duration(minutes: 5);
  static const maxPerDay = 3;

  static const _lastKey = 'ads.interstitial.lastShownMs';
  static const _dayKey = 'ads.interstitial.day';
  static const _countKey = 'ads.interstitial.count';

  bool get canShow {
    final now = _clock();
    final lastMs = _prefs.getInt(_lastKey);
    if (lastMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) < minGap) {
      return false;
    }
    return _countFor(now) < maxPerDay;
  }

  Future<void> recordShown() async {
    final now = _clock();
    final count = _countFor(now) + 1;
    await _prefs.setInt(_lastKey, now.millisecondsSinceEpoch);
    await _prefs.setString(_dayKey, _day(now));
    await _prefs.setInt(_countKey, count);
  }

  int _countFor(DateTime now) => _prefs.getString(_dayKey) == _day(now)
      ? _prefs.getInt(_countKey) ?? 0
      : 0;

  static String _day(DateTime t) => '${t.year}-${t.month}-${t.day}';
}
