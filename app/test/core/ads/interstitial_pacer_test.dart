import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/ads/interstitial_pacer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 4, 10);
  });

  InterstitialPacer pacer() => InterstitialPacer.withClock(prefs, () => now);

  test('allows the first ad of the day', () {
    expect(pacer().canShow, isTrue);
  });

  test('blocks a second ad within five minutes', () async {
    await pacer().recordShown();
    now = now.add(const Duration(minutes: 4, seconds: 59));

    expect(pacer().canShow, isFalse);
  });

  test('allows another ad after five minutes', () async {
    await pacer().recordShown();
    now = now.add(InterstitialPacer.minGap);

    expect(pacer().canShow, isTrue);
  });

  test('stops after three ads in one day', () async {
    for (var i = 0; i < InterstitialPacer.maxPerDay; i++) {
      await pacer().recordShown();
      now = now.add(const Duration(hours: 1));
    }

    expect(pacer().canShow, isFalse);
  });

  test('resets the daily count the next day', () async {
    for (var i = 0; i < InterstitialPacer.maxPerDay; i++) {
      await pacer().recordShown();
      now = now.add(const Duration(minutes: 10));
    }
    now = DateTime(2026, 10, 5, 9);

    expect(pacer().canShow, isTrue);
  });

  test('survives a restart (state is persisted)', () async {
    await pacer().recordShown();
    final restarted = InterstitialPacer.withClock(
      prefs,
      () => now.add(const Duration(minutes: 1)),
    );

    expect(restarted.canShow, isFalse);
  });
}
