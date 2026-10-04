import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';

/// Starts the Mobile Ads SDK once, on first use rather than at launch: the
/// splash and Pro users never pay for it.
@lazySingleton
class MobileAdsBootstrap {
  Future<void>? _initialized;

  /// Test devices, comma-separated: `--dart-define=ADMOB_TEST_DEVICE_IDS=id1,id2`.
  /// Devices registered in the AdMob console work without this; it covers the
  /// delay before the console registration takes effect. The id is printed in
  /// the device log ("Use RequestConfiguration.Builder().setTestDeviceIds…").
  static const _testDeviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

  Future<void> ensureInitialized() => _initialized ??= _start();

  Future<void> _start() async {
    final ids = [
      for (final id in _testDeviceIds.split(','))
        if (id.trim().isNotEmpty) id.trim(),
    ];
    if (ids.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ids),
      );
    }
    await MobileAds.instance.initialize();
  }
}
