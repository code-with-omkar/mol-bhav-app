import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../monetization/presentation/ads/ads_visibility.dart';
import '../../monetization/presentation/ads/native_ad_slot.dart';
import '../domain/promotions.dart';
import 'sponsored_card.dart';

/// One ad slot: a direct-sold sponsor when one is booked for this user and
/// [placement] (better paid, and relevant to their categories), otherwise an
/// AdMob native ad. Nothing at all for Pro users, on web, or until the profile
/// says the user is on the free plan — the same rule as [NativeAdSlot].
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, required this.placement});

  final PromotionPlacement placement;

  @override
  Widget build(BuildContext context) => context.showsAds
      ? _AdSlot(placement: placement)
      : const SizedBox.shrink();
}

class _AdSlot extends StatefulWidget {
  const _AdSlot({required this.placement});

  final PromotionPlacement placement;

  @override
  State<_AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<_AdSlot> {
  Promotion? _promotion;

  /// Until the server answers nothing is shown, so a sponsor's card never
  /// replaces an AdMob ad that was already requested (a wasted request).
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement == widget.placement) return;
    setState(() {
      _promotion = null;
      _resolved = false;
    });
    _load();
  }

  Future<void> _load() async {
    final placement = widget.placement;
    final result = await getIt<GetPromotion>()(placement);
    // Unmounted, or re-pointed at another placement while this was loading.
    if (!mounted || widget.placement != placement) return;
    setState(() {
      // Any failure falls back to AdMob: the slot is never just empty.
      _promotion = result.fold((_) => null, (p) => p);
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) return const SizedBox.shrink();
    final promotion = _promotion;
    return promotion == null
        ? const NativeAdSlot()
        : SponsoredCard(promotion: promotion);
  }
}
