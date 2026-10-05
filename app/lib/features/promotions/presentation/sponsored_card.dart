import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../data/promotion_events_tracker.dart';
import '../domain/promotions.dart';

/// A direct-sold sponsorship in the app's own card style, always labelled
/// "Sponsored" with the advertiser's name so it can't pass for price data.
///
/// An impression counts once per card, the first time at least half of it is
/// on screen (the usual viewability bar), so a card at the bottom of a long
/// list that nobody scrolls to is not billed. Only the button opens the link,
/// so a scroll that brushes the card is never a click.
class SponsoredCard extends StatefulWidget {
  const SponsoredCard({super.key, required this.promotion, this.tracker});

  final Promotion promotion;

  /// Defaults to the app-wide tracker; injectable for tests.
  final PromotionEventsTracker? tracker;

  @override
  State<SponsoredCard> createState() => _SponsoredCardState();
}

class _SponsoredCardState extends State<SponsoredCard> {
  static const _viewableFraction = 0.5;

  /// Stable across rebuilds, unique per card — VisibilityDetector needs both.
  final Key _visibilityKey = UniqueKey();
  bool _counted = false;

  PromotionEventsTracker get _tracker =>
      widget.tracker ?? getIt<PromotionEventsTracker>();

  void _onVisibility(VisibilityInfo info) {
    if (_counted || info.visibleFraction < _viewableFraction) return;
    _counted = true;
    _tracker.impression(widget.promotion.campaignId);
  }

  Future<void> _open() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = context.l10n.cannotOpenLink;
    _tracker.click(widget.promotion.campaignId);
    var opened = false;
    try {
      opened = await launchUrl(
        widget.promotion.ctaUrl,
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    final c = context.mbColors;
    final t = context.mbText;
    final image = p.imageUrl;

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibility,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MbSpacing.s2),
        child: Semantics(
          container: true,
          label: '${context.l10n.promotionSponsored}, ${p.advertiserName}',
          child: MbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surfaceAmberSoft,
                        borderRadius: BorderRadius.circular(MbRadius.sm),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MbSpacing.s2,
                          vertical: 2,
                        ),
                        child: Text(
                          context.l10n.promotionSponsored,
                          style: t.label.copyWith(color: c.accentText),
                        ),
                      ),
                    ),
                    const SizedBox(width: MbSpacing.s2),
                    Expanded(
                      child: Text(
                        p.advertiserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ],
                ),
                if (image != null) ...[
                  const SizedBox(height: MbSpacing.s3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(MbRadius.md),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      // Disk-cached: a sponsor's banner downloads once, not on
                      // every Home visit.
                      child: CachedNetworkImage(
                        imageUrl: image.toString(),
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            ColoredBox(color: c.surfaceGreenSoft),
                        // A broken image must not leave a hole in the card.
                        errorWidget: (_, _, _) =>
                            ColoredBox(color: c.surfaceGreenSoft),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: MbSpacing.s3),
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: MbSpacing.s1),
                Text(
                  p.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s3),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: MbButton(
                    label: p.ctaLabel,
                    onPressed: _open,
                    variant: MbButtonVariant.secondary,
                    size: MbButtonSize.sm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
