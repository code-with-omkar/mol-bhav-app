import 'package:flutter/foundation.dart';

/// Ad unit ids. Google's test units are the defaults so debug builds never
/// serve (or get paid for) real ads; release builds pass the real ids, e.g.
/// `--dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-…/…`.
abstract final class AdsConfig {
  static const _rewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const _rewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );
  static const _nativeAndroid = String.fromEnvironment(
    'ADMOB_NATIVE_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110',
  );
  static const _nativeIos = String.fromEnvironment(
    'ADMOB_NATIVE_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/3986624511',
  );
  static const _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/9214589741',
  );
  static const _bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2435281174',
  );
  static const _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  /// The Google Mobile Ads SDK runs on Android and iOS only — not on web.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get rewardedUnitId => _ios ? _rewardedIos : _rewardedAndroid;

  static String get nativeUnitId => _ios ? _nativeIos : _nativeAndroid;

  static String get bannerUnitId => _ios ? _bannerIos : _bannerAndroid;

  static String get interstitialUnitId =>
      _ios ? _interstitialIos : _interstitialAndroid;
}
