import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/ads/ad_request_factory.dart';
import '../../../../core/ads/ads_config.dart';
import '../../../../core/ads/mobile_ads_bootstrap.dart';
import '../../../../core/di/injection.dart';
import 'ads_visibility.dart';

/// An anchored adaptive banner for a screen's bottom edge. Collapses to
/// nothing for Pro users, on web, and until (or unless) an ad loads, so the
/// layout never shows an empty grey strip.
class BannerAdSlot extends StatelessWidget {
  const BannerAdSlot({super.key});

  @override
  Widget build(BuildContext context) =>
      context.showsAds ? const _Banner() : const SizedBox.shrink();
}

class _Banner extends StatefulWidget {
  const _Banner();

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  int? _width;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width.truncate();
    // Reload when the width changes (rotation); the size is width-specific.
    if (width != _width) {
      _width = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    await getIt<MobileAdsBootstrap>().ensureInitialized();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || width != _width) return;

    final old = _ad;
    final ad = BannerAd(
      adUnitId: AdsConfig.bannerUnitId,
      request: getIt<AdRequestFactory>().build(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (mounted && identical(_ad, loaded)) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          // A banner replaced after a rotation must not clear its successor.
          if (mounted && identical(_ad, failed)) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    // Swap first, then dispose: the old AdWidget must leave the tree before
    // its ad is released.
    setState(() {
      _ad = ad;
      _size = size;
      _loaded = false;
    });
    await old?.dispose();
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;
    if (ad == null || size == null || !_loaded) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
