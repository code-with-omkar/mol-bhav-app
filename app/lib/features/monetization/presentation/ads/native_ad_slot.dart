import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/ads/ad_request_factory.dart';
import '../../../../core/ads/ads_config.dart';
import '../../../../core/ads/mobile_ads_bootstrap.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import 'ads_visibility.dart';

/// A native ad in Google's small template, styled like the app's cards.
/// Takes no space until an ad has loaded, and none at all for Pro users,
/// on web, or when no ad is available. The template carries its own "Ad"
/// label, so it can't be mistaken for price data.
class NativeAdSlot extends StatelessWidget {
  const NativeAdSlot({super.key});

  @override
  Widget build(BuildContext context) =>
      context.showsAds ? const _NativeAd() : const SizedBox.shrink();
}

class _NativeAd extends StatefulWidget {
  const _NativeAd();

  @override
  State<_NativeAd> createState() => _NativeAdState();
}

class _NativeAdState extends State<_NativeAd> {
  NativeAd? _ad;
  bool _loaded = false;

  /// One attempt per slot: a theme or locale change must not re-request.
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load();
  }

  Future<void> _load() async {
    final c = context.mbColors;
    final ad = NativeAd(
      adUnitId: AdsConfig.nativeUnitId,
      request: getIt<AdRequestFactory>().build(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: c.surfaceCard,
        cornerRadius: MbRadius.lg,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: c.onPrimary,
          backgroundColor: c.primary,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(textColor: c.ink, size: 15),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: c.inkMuted,
          size: 13,
        ),
      ),
    );
    _ad = ad;
    await getIt<MobileAdsBootstrap>().ensureInitialized();
    if (!mounted) return;
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
    if (ad == null || !_loaded) return const SizedBox.shrink();
    // Google's small template needs 320–400 wide; on narrower screens skip
    // the ad rather than overflow.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 320
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: MbSpacing.s2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    minHeight: 90,
                    maxWidth: 400,
                    maxHeight: 200,
                  ),
                  child: SizedBox(height: 110, child: AdWidget(ad: ad)),
                ),
              ),
            ),
    );
  }
}
