import 'package:injectable/injectable.dart';

/// Emits the seconds remaining, once a second, from `seconds - 1` down to 0.
/// Injected so tests can drive time.
@injectable
class Countdown {
  const Countdown();

  Stream<int> start(int seconds) => Stream<int>.periodic(
    const Duration(seconds: 1),
    (tick) => seconds - tick - 1,
  ).take(seconds);
}
