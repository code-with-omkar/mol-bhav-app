import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_button.dart';
import 'mb_icon.dart';
import 'mb_price.dart';

/// Today's opportunity: product, price with change and sparkline, the
/// market insight and an action.
class MbOpportunityCard extends StatelessWidget {
  const MbOpportunityCard({
    super.key,
    required this.product,
    required this.price,
    this.meta,
    this.time,
    this.unit,
    this.change,
    this.percent,
    this.trend,
    this.insight,
    this.thumb = MbIcons.agriculture,
    this.tone = MbTone.green,
    this.actionLabel,
    this.onAction,
  });

  final String product;
  final String price;
  final String? meta;
  final String? time;
  final String? unit;
  final num? change;
  final double? percent;
  final List<num>? trend;
  final String? insight;
  final MbIcons thumb;
  final MbTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Container(
      padding: const EdgeInsets.all(MbSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: Border.all(color: c.border),
        boxShadow: c.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MbThumb(icon: thumb, tone: tone),
              const SizedBox(width: MbSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product, style: t.price.copyWith(color: c.ink)),
                    if (meta != null)
                      Text(meta!, style: t.caption.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              if (time != null) ...[
                const SizedBox(width: MbSpacing.s2),
                Text(time!, style: t.micro.copyWith(color: c.inkMuted)),
              ],
            ],
          ),
          const SizedBox(height: MbSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MbPriceText(
                        price: price,
                        unit: unit,
                        style: t.priceLg.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(height: 2),
                    MbPriceChange(value: change, percent: percent, large: true),
                  ],
                ),
              ),
              if (trend != null)
                MbSparkline(data: trend!, width: 96, height: 40),
            ],
          ),
          const SizedBox(height: MbSpacing.s3),
          Row(
            children: [
              if (insight != null)
                Flexible(
                  child: MbBadge(label: insight!, icon: MbIcons.market),
                ),
              const Spacer(),
              if (actionLabel != null)
                MbButton(
                  label: actionLabel!,
                  variant: MbButtonVariant.secondary,
                  size: MbButtonSize.sm,
                  onPressed: onAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum MbAlertVariant { signal, spike, opportunity }

/// Price signal / spike / opportunity alert.
class MbAlertCard extends StatelessWidget {
  const MbAlertCard({
    super.key,
    required this.variant,
    required this.kind,
    required this.title,
    this.time,
    this.details = const [],
    this.channel,
    this.unread = false,
    this.actionLabel,
    this.onAction,
  });

  final MbAlertVariant variant;
  final String kind;
  final String title;
  final String? time;
  final List<String> details;
  final String? channel;
  final bool unread;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final (MbIcons icon, Color bg, Color fg) = switch (variant) {
      MbAlertVariant.signal => (MbIcons.trendDown, c.surfaceGreen, c.priceDown),
      MbAlertVariant.spike => (MbIcons.trend, c.surfaceAmber, c.priceUp),
      MbAlertVariant.opportunity => (
        MbIcons.opportunity,
        c.surfaceAmber,
        c.accentText,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(MbSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.md),
        border: Border.all(color: unread ? c.accent : c.border),
        boxShadow: c.shadowCard,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: MbIcon(icon, size: 16, strokeWidth: 2.25, color: fg),
          ),
          const SizedBox(width: MbSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(kind, style: t.button.copyWith(color: c.ink)),
                    ),
                    if (time != null)
                      Text(time!, style: t.micro.copyWith(color: c.inkMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(title, style: t.fieldLabel.copyWith(color: c.ink)),
                for (final detail in details) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: t.cardSubtitle.copyWith(
                      color: c.inkMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (channel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MbIcon(MbIcons.message, size: 12, color: c.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        channel!,
                        style: t.micro.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: MbSpacing.s3),
                  MbButton(
                    label: actionLabel!,
                    size: MbButtonSize.sm,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Subscription plan: name, price, feature list and an action.
class MbPlanCard extends StatelessWidget {
  const MbPlanCard({
    super.key,
    required this.name,
    required this.price,
    this.period,
    this.features = const [],
    this.featured = false,
    this.currentLabel,
    this.actionLabel,
    this.onAction,
  });

  final String name;
  final String price;

  /// Already formatted, e.g. `/ month`.
  final String? period;
  final List<String> features;
  final bool featured;

  /// Badge text when this is the user's plan.
  final String? currentLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Container(
      padding: const EdgeInsets.all(MbSpacing.s5),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: Border.all(color: featured ? c.primary : c.border),
        boxShadow: featured
            ? [BoxShadow(color: c.primary, spreadRadius: 1), ...c.shadowCard]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (featured) ...[
                MbIcon(MbIcons.pro, size: 18, color: c.accentText),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(name, style: t.stat.copyWith(color: c.ink)),
              ),
              if (currentLabel != null)
                MbBadge(label: currentLabel!, tone: MbBadgeTone.neutral),
            ],
          ),
          const SizedBox(height: MbSpacing.s3),
          Text.rich(
            TextSpan(
              text: price,
              children: [
                if (period != null)
                  TextSpan(
                    text: ' $period',
                    style: t.body.copyWith(fontSize: 13, color: c.inkMuted),
                  ),
              ],
            ),
            style: t.valueLg.copyWith(color: c.ink),
          ),
          const SizedBox(height: MbSpacing.s3),
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: MbSpacing.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: MbIcon(
                    MbIcons.check,
                    size: 16,
                    strokeWidth: 2.5,
                    color: c.primaryText,
                  ),
                ),
                const SizedBox(width: MbSpacing.s2),
                Expanded(
                  child: Text(
                    features[i],
                    style: t.body.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: MbSpacing.s3),
            MbButton(
              label: actionLabel!,
              block: true,
              variant: featured
                  ? MbButtonVariant.primary
                  : MbButtonVariant.secondary,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
