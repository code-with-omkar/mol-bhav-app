import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/mb_wordmark.dart';
import 'price_share_data.dart';

/// The card that becomes the shared PNG. Built from the live theme and the
/// active locale, so the image carries the user's own language and the brand
/// fonts the rest of the app uses.
class SharePriceCard extends StatelessWidget {
  const SharePriceCard({super.key, required this.data});

  /// Fixed width: the capture must not depend on the screen it was taken on,
  /// or the same card would come out differently on a tablet.
  static const width = 420.0;

  final PriceShareData data;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      width: width,
      padding: const EdgeInsets.all(MbSpacing.s5),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MbWordmark(size: 22),
          const SizedBox(height: MbSpacing.s4),
          Text(data.title, style: t.h2.copyWith(color: c.ink)),
          const SizedBox(height: 2),
          Text(data.mandiName, style: t.body.copyWith(color: c.inkMuted)),
          const SizedBox(height: MbSpacing.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: MbSpacing.s3,
              horizontal: MbSpacing.s4,
            ),
            decoration: BoxDecoration(
              color: c.surfaceGreen,
              borderRadius: BorderRadius.circular(MbRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareModalLabel,
                  style: t.label.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatInr(data.modalPrice)}/${data.unitSymbol}',
                  style: t.valueLg.copyWith(color: c.ink),
                ),
                if (data.hasRange) ...[
                  const SizedBox(height: MbSpacing.s2),
                  Text(
                    l10n.shareRange(
                      formatInr(data.minPrice!),
                      formatInr(data.maxPrice!),
                    ),
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: MbSpacing.s4),
          Text(
            l10n.priceDate(formatDayMonth(data.recordDate, locale)),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          Text(
            l10n.sourceLine(data.source),
            style: t.microStrong.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}
