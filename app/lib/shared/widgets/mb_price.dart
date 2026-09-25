import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import '../../core/utils/formatters.dart';
import 'mb_icon.dart';

/// Tint for thumbs, icon discs and panels.
enum MbTone { neutral, green, amber, navy }

enum PriceDirection { up, down, flat }

PriceDirection directionOf(num? value) => value == null || value == 0
    ? PriceDirection.flat
    : value > 0
    ? PriceDirection.up
    : PriceDirection.down;

/// Signed, arrowed price change. Buyer-centric: a rise is red ↑, a drop is
/// green ↓ — never colour alone.
class MbPriceChange extends StatelessWidget {
  const MbPriceChange({
    super.key,
    this.value,
    this.percent,
    this.currency = true,
    this.large = false,
  });

  /// Absolute rupee change; its sign sets the direction.
  final num? value;

  /// Percent change; sets the direction when [value] is absent.
  final double? percent;

  /// `false` drops the ₹ prefix (column already labelled ₹).
  final bool currency;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final dir = directionOf(value ?? percent);
    final parts = [
      if (value != null) '${currency ? '₹' : ''}${formatIndian(value!.abs())}',
      if (percent != null)
        '${percent! > 0
            ? '+'
            : percent! < 0
            ? '-'
            : ''}${percent!.abs().toStringAsFixed(1)}%',
    ];
    final text = parts.isEmpty ? '—' : parts.join('  ');
    final color = switch (dir) {
      PriceDirection.up => c.priceUp,
      PriceDirection.down => c.priceDown,
      PriceDirection.flat => c.inkMuted,
    };
    final label = switch (dir) {
      PriceDirection.up => l10n.priceUp,
      PriceDirection.down => l10n.priceDown,
      PriceDirection.flat => l10n.priceFlat,
    };
    final style = context.mbText.change;

    return Semantics(
      label: '$label $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MbIcon(
            switch (dir) {
              PriceDirection.up => MbIcons.arrowUp,
              PriceDirection.down => MbIcons.arrowDown,
              PriceDirection.flat => MbIcons.minus,
            },
            size: large ? 14 : 12,
            strokeWidth: 2.5,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: large
                ? style.copyWith(fontSize: 13, height: 18 / 13, color: color)
                : style.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// 32px tinted square holding a category or concept icon.
class MbThumb extends StatelessWidget {
  const MbThumb({super.key, required this.icon, this.tone = MbTone.neutral});

  final MbIcons icon;
  final MbTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final (Color bg, Color fg) = switch (tone) {
      MbTone.green => (c.surfaceGreen, c.primaryText),
      MbTone.amber => (c.surfaceAmber, c.accentText),
      MbTone.navy => (c.hero, c.bhavAmber),
      MbTone.neutral => (c.surfaceGreenSoft, c.inkMuted),
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MbRadius.sm),
      ),
      child: MbIcon(icon, size: 16, color: fg),
    );
  }
}

/// Axis-less mini trend; colour follows the first→last direction.
class MbSparkline extends StatelessWidget {
  const MbSparkline({
    super.key,
    required this.data,
    this.width = 80,
    this.height = 28,
  });

  final List<num> data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);
    final c = context.mbColors;
    final color = switch (directionOf(data.last - data.first)) {
      PriceDirection.up => c.priceUp,
      PriceDirection.down => c.priceDown,
      PriceDirection.flat => c.inkMuted,
    };
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparkPainter(data, color),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.data, this.color);

  final List<num> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 3.0;
    final lo = data.reduce((a, b) => a < b ? a : b);
    final hi = data.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    final points = [
      for (var i = 0; i < data.length; i++)
        Offset(
          pad + i * (size.width - 2 * pad) / (data.length - 1),
          pad + (1 - (data[i] - lo) / span) * (size.height - 2 * pad),
        ),
    ];
    final path = Path()..addPolygon(points, false);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(points.last, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || old.data != data;
}

/// `₹58,200` with a muted `/MT` unit.
class MbPriceText extends StatelessWidget {
  const MbPriceText({
    super.key,
    required this.price,
    this.unit,
    this.style,
    this.unitStyle,
  });

  final String price;
  final String? unit;
  final TextStyle? style;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Text.rich(
      TextSpan(
        text: price,
        children: [
          if (unit != null)
            TextSpan(
              text: '/$unit',
              style: unitStyle ?? t.caption.copyWith(color: c.inkMuted),
            ),
        ],
      ),
      style: style ?? t.price.copyWith(color: c.ink),
      textAlign: TextAlign.right,
    );
  }
}

/// One market / watchlist / comparison row. Place rows in an [MbGroup] or
/// [MbPriceTable], which draw the dividers.
class MbPriceRow extends StatelessWidget {
  const MbPriceRow({
    super.key,
    required this.name,
    required this.price,
    this.meta,
    this.thumb,
    this.thumbTone = MbTone.neutral,
    this.unit,
    this.change,
    this.percent,
    this.changeCurrency = true,
    this.best = false,
    this.badge,
    this.trend,
    this.stacked = false,
    this.onTap,
  });

  final String name;

  /// Pre-formatted price, e.g. `₹2,150` or `₹26.20`.
  final String price;
  final String? meta;
  final MbIcons? thumb;
  final MbTone thumbTone;
  final String? unit;
  final num? change;
  final double? percent;
  final bool changeCurrency;
  final bool best;
  final Widget? badge;
  final List<num>? trend;

  /// Stack price above change (narrow rows with a sparkline).
  final bool stacked;
  final VoidCallback? onTap;

  bool get _hasChange => change != null || percent != null;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final priceChange = _hasChange
        ? MbPriceChange(
            value: change,
            percent: percent,
            currency: changeCurrency,
          )
        : null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: MbSpacing.s3,
        horizontal: MbSpacing.s4,
      ),
      child: Row(
        children: [
          if (thumb != null) ...[
            MbThumb(icon: thumb!, tone: thumbTone),
            const SizedBox(width: MbSpacing.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.rowName.copyWith(color: c.ink)),
                if (meta != null)
                  Text(meta!, style: t.caption.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          if (trend != null) ...[
            const SizedBox(width: MbSpacing.s3),
            MbSparkline(data: trend!, width: 56, height: 22),
          ],
          if (badge != null) ...[const SizedBox(width: MbSpacing.s3), badge!],
          const SizedBox(width: MbSpacing.s3),
          if (stacked)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MbPriceText(price: price, unit: unit),
                if (priceChange != null) ...[
                  const SizedBox(height: 2),
                  priceChange,
                ],
              ],
            )
          else ...[
            MbPriceText(price: price, unit: unit),
            if (priceChange != null) ...[
              const SizedBox(width: MbSpacing.s3),
              SizedBox(
                width: 76,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: priceChange,
                ),
              ),
            ],
          ],
        ],
      ),
    );

    return Material(
      color: best ? c.surfaceGreenSoft : c.surfaceCard,
      shape: best
          ? Border.fromBorderSide(BorderSide(color: c.surfaceGreen))
          : null,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

/// Grouped rows in one bordered card with hairline dividers (`.mb-group`).
class MbGroup extends StatelessWidget {
  const MbGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Comparison matrix: a header row, then [MbPriceRow]s.
class MbPriceTable extends StatelessWidget {
  const MbPriceTable({
    super.key,
    required this.nameHeader,
    required this.priceHeader,
    required this.rows,
    this.changeHeader,
  });

  final String nameHeader;
  final String priceHeader;
  final String? changeHeader;
  final List<MbPriceRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final style = context.mbText.label.copyWith(color: c.inkMuted);
    return MbGroup(
      children: [
        Container(
          color: c.surfaceGreenSoft,
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: MbSpacing.s4,
          ),
          child: Row(
            children: [
              Expanded(child: Text(nameHeader, style: style)),
              Text(priceHeader, style: style, textAlign: TextAlign.right),
              if (changeHeader != null) ...[
                const SizedBox(width: MbSpacing.s3),
                SizedBox(
                  width: 76,
                  child: Text(
                    changeHeader!,
                    style: style,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...rows,
      ],
    );
  }
}

enum MbBadgeTone { best, bestSolid, opportunity, neutral, pro }

/// Small pill label: "Best Price", "Pro", "Current plan".
class MbBadge extends StatelessWidget {
  const MbBadge({
    super.key,
    required this.label,
    this.tone = MbBadgeTone.best,
    this.icon,
  });

  final String label;
  final MbBadgeTone tone;
  final MbIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final (Color bg, Color fg) = switch (tone) {
      MbBadgeTone.best => (c.surfaceGreen, c.primaryText),
      MbBadgeTone.bestSolid => (c.primary, c.onPrimary),
      MbBadgeTone.opportunity => (c.surfaceAmber, c.accentText),
      MbBadgeTone.neutral => (c.surfaceGreenSoft, c.inkMuted),
      MbBadgeTone.pro => (c.hero, c.bhavAmber),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MbRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            MbIcon(icon!, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: context.mbText.label.copyWith(color: fg)),
        ],
      ),
    );
  }
}
