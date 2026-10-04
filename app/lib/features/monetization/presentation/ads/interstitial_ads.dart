import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/ads/ad_request_factory.dart';
import '../../../../core/ads/ads_config.dart';
import '../../../../core/ads/interstitial_pacer.dart';
import '../../../../core/ads/mobile_ads_bootstrap.dart';
import '../../../account/presentation/profile_cubit.dart';

/// Full-screen ads at natural breaks only (after a share, when the user backs
/// out of Reports after a download) — never at launch or exit. [warmUp]
/// preloads one ahead of time, because an ad that pops up late over new
/// content is itself a policy violation; [showIfDue] shows it only when one is
/// ready, the app is in the foreground and the [InterstitialPacer] allows.
@lazySingleton
class InterstitialAds {
  InterstitialAds(this._bootstrap, this._requests, this._pacer, this._profile);

  final MobileAdsBootstrap _bootstrap;
  final AdRequestFactory _requests;
  final InterstitialPacer _pacer;
  final ProfileCubit _profile;

  /// Google expires a loaded interstitial after about an hour.
  static const _maxAge = Duration(minutes: 55);

  InterstitialAd? _ready;
  DateTime? _loadedAt;
  bool _loading = false;

  bool get _eligible =>
      AdsConfig.isSupported && _profile.state.data?.isPro == false;

  /// Preloads one ad if none is waiting; cheap to call repeatedly.
  Future<void> warmUp() async {
    _dropIfStale();
    if (!_eligible || _ready != null || _loading || !_pacer.canShow) return;
    _loading = true;
    try {
      await _bootstrap.ensureInitialized();
      await InterstitialAd.load(
        adUnitId: AdsConfig.interstitialUnitId,
        request: _requests.build(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ready = ad;
            _loadedAt = DateTime.now();
            _loading = false;
          },
          onAdFailedToLoad: (_) => _loading = false,
        ),
      );
    } on Object {
      _loading = false;
    }
  }

  /// Shows the preloaded ad if the user is still a free user, the app is in
  /// the foreground (a share target may still be opening) and the pacing
  /// allows; otherwise keeps it for the next break. Never loads-and-shows.
  Future<void> showIfDue() async {
    _dropIfStale();
    final ad = _ready;
    if (ad == null || !_eligible || !_pacer.canShow) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _ready = null;
    _loadedAt = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      // Counted only once it is really on screen, so a failed show doesn't
      // use up one of the day's slots.
      onAdShowedFullScreenContent: (_) => _pacer.recordShown(),
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
    );
    await ad.show();
  }

  void _dropIfStale() {
    final loadedAt = _loadedAt;
    if (_ready != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) > _maxAge) {
      _ready!.dispose();
      _ready = null;
      _loadedAt = null;
    }
  }
}
