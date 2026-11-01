import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/settings/home_weather_animation_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('is on by default', () {
    expect(HomeWeatherAnimationCubit(prefs).state, isTrue);
  });

  test('turning it off is saved', () async {
    final cubit = HomeWeatherAnimationCubit(prefs);

    await cubit.set(false);

    expect(cubit.state, isFalse);
    expect(prefs.getBool(HomeWeatherAnimationCubit.key), isFalse);
  });

  test('a saved choice survives a restart', () async {
    await HomeWeatherAnimationCubit(prefs).set(false);

    expect(HomeWeatherAnimationCubit(prefs).state, isFalse);
  });

  test('turning it back on is saved', () async {
    final cubit = HomeWeatherAnimationCubit(prefs);
    await cubit.set(false);

    await cubit.set(true);

    expect(prefs.getBool(HomeWeatherAnimationCubit.key), isTrue);
  });
}
