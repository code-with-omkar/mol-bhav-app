import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';

import 'ad_request_factory.dart';
import 'ads_config.dart';
import 'mobile_ads_bootstrap.dart';

enum RewardedAdOutcome {
  /// Watched to the end; the server hears about it through AdMob's signed
  /// callback, so this alone grants nothing.
  earned,

  /// Closed early — no reward.
  dismissed,

  /// No ad could be loaded (no inventory, offline, unsupported platform).
  noFill,

  /// Loaded but could not be shown.
  failed,
}

/// Loads and shows one rewarded ad. [play]'s `customData` travels to the API
/// in AdMob's server-side-verification callback — that is how a view is tied
/// to the unlock it pays for.
@lazySingleton
class RewardedAdPlayer {
  RewardedAdPlayer(this._bootstrap, this._requests);

  final MobileAdsBootstrap _bootstrap;
  final AdRequestFactory _requests;

  Future<RewardedAdOutcome> play({
    required String userId,
    required String customData,
  }) async {
    if (!AdsConfig.isSupported) return RewardedAdOutcome.noFill;
    await _bootstrap.ensureInitialized();

    final loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: AdsConfig.rewardedUnitId,
      request: _requests.build(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (_) => loaded.complete(null),
      ),
    );
    final ad = await loaded.future;
    if (ad == null) return RewardedAdOutcome.noFill;

    await ad.setServerSideOptions(
      ServerSideVerificationOptions(userId: userId, customData: customData),
    );

    final finished = Completer<RewardedAdOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!finished.isCompleted) {
          finished.complete(
            earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!finished.isCompleted) finished.complete(RewardedAdOutcome.failed);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return finished.future;
  }
}
