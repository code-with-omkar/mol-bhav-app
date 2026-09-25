import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_colors.dart';
import '../../core/theme/mb_dimens.dart';
import '../../core/theme/mb_typography.dart';
import '../../core/utils/formatters.dart';

class MbTrendPoint {
  const MbTrendPoint({required this.label, required this.value});

  final String label;
  final num value;
}

/// Single-series line chart with a crosshair tooltip. Drag or tap to
/// inspect a point; releasing returns to [highlightIndex] (default: last).
class MbTrendChart extends StatefulWidget {
  const MbTrendChart({
    super.key,
    required this.data,
    this.title,
    this.highlightIndex,
    this.height = 200,
    this.format = formatInr,
  });

  final List<MbTrendPoint> data;
  final String? title;
  final int? highlightIndex;
  final double height;
  final String Function(num value) format;

  @override
  State<MbTrendChart> createState() => _MbTrendChartState();
}

class _MbTrendChartState extends State<MbTrendChart> {
  int? _active;

  int get _resting => widget.highlightIndex ?? widget.data.length - 1;

  void _inspect(Offset local, double width) {
    final geometry = _Geometry(widget.data, Size(width, widget.height));
    setState(() => _active = geometry.indexAt(local.dx));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final active = (_active ?? _resting).clamp(0, widget.data.length - 1);
    final point = widget.data[active];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        MbSpacing.s3,
        MbSpacing.s4,
        MbSpacing.s3,
        MbSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: MbSpacing.s2),
              child: Text(
                widget.title!,
                style: t.fieldLabel.copyWith(color: c.ink),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, widget.height);
              final geometry = _Geometry(widget.data, size);
              final anchor = geometry.point(active);
              return Semantics(
                label:
                    '${widget.title ?? ''}, ${widget.format(widget.data.last.value)}',
                child: GestureDetector(
                  onTapDown: (d) => _inspect(d.localPosition, size.width),
                  onHorizontalDragUpdate: (d) =>
                      _inspect(d.localPosition, size.width),
                  onHorizontalDragEnd: (_) => setState(() => _active = null),
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: size,
                          painter: _ChartPainter(
                            geometry: geometry,
                            active: active,
                            colors: c,
                            type: t,
                          ),
                        ),
                        Positioned(
                          left: anchor.dx,
                          top: anchor.dy - 12,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -1),
                            child: _Tooltip(
                              value: widget.format(point.value),
                              label: point.label,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: c.hero,
          borderRadius: BorderRadius.circular(MbRadius.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: t.change.copyWith(color: c.inkOnHero)),
            Text(label, style: t.axis.copyWith(color: c.inkOnHero)),
          ],
        ),
      ),
    );
  }
}

/// Plot layout in the design's 340-wide coordinate system, scaled to size.
class _Geometry {
  _Geometry(this.data, this.size) {
    final values = data.map((p) => p.value.toDouble());
    ticks = _niceTicks(values.reduce(math.min), values.reduce(math.max), 4);
  }

  static const left = 40.0, right = 12.0, top = 16.0, bottom = 26.0;

  final List<MbTrendPoint> data;
  final Size size;
  late final List<double> ticks;

  double get _step =>
      (size.width - left - right) / math.max(1, data.length - 1);

  double x(int i) => left + i * _step;

  double y(num v) {
    final lo = ticks.first, hi = ticks.last;
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    return top + (1 - (v - lo) / span) * (size.height - top - bottom);
  }

  Offset point(int i) => Offset(x(i), y(data[i].value));

  int indexAt(double dx) =>
      ((dx - left) / _step).round().clamp(0, data.length - 1);

  static List<double> _niceTicks(double min, double max, int n) {
    final span = (max - min) == 0 ? 1.0 : max - min;
    var step = math
        .pow(10, (math.log(span / n) / math.ln10).floor())
        .toDouble();
    for (final m in const [1, 2, 2.5, 5, 10]) {
      if (span / (step * m) <= n) {
        step *= m;
        break;
      }
    }
    final lo = (min / step).floor() * step;
    final hi = (max / step).ceil() * step;
    return [for (var v = lo; v <= hi + 1e-9; v += step) v];
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.geometry,
    required this.active,
    required this.colors,
    required this.type,
  });

  final _Geometry geometry;
  final int active;
  final MbColors colors;
  final MbTypography type;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final axisStyle = type.axis.copyWith(color: colors.inkMuted);
    final grid = Paint()
      ..color = colors.border
      ..strokeWidth = 1;

    for (final tick in g.ticks) {
      final y = g.y(tick);
      canvas.drawLine(
        Offset(_Geometry.left, y),
        Offset(size.width - _Geometry.right, y),
        grid,
      );
      _text(
        canvas,
        formatIndian(tick),
        axisStyle,
        Offset(_Geometry.left - 6, y),
        align: TextAlign.right,
      );
    }

    final every = (g.data.length / 5).ceil();
    for (var i = 0; i < g.data.length; i++) {
      if (i % every != 0 && i != g.data.length - 1) continue;
      final align = i == 0
          ? TextAlign.left
          : i == g.data.length - 1
          ? TextAlign.right
          : TextAlign.center;
      _text(
        canvas,
        g.data[i].label,
        axisStyle,
        Offset(g.x(i), size.height - 6),
        align: align,
      );
    }

    // Dashed crosshair.
    final anchor = g.point(active);
    final cross = Paint()
      ..color = colors.borderStrong
      ..strokeWidth = 1;
    for (var y = _Geometry.top; y < size.height - _Geometry.bottom; y += 6) {
      canvas.drawLine(
        Offset(anchor.dx, y),
        Offset(anchor.dx, math.min(y + 3, size.height - _Geometry.bottom)),
        cross,
      );
    }

    final path = Path()
      ..addPolygon([for (var i = 0; i < g.data.length; i++) g.point(i)], false);
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(anchor, 6, Paint()..color = colors.surfaceCard)
      ..drawCircle(anchor, 4, Paint()..color = colors.primary);
  }

  /// Draws [text] with its baseline-ish bottom at [at]; [align] picks which
  /// edge sits on `at.dx`.
  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at, {
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - painter.width,
      TextAlign.center => at.dx - painter.width / 2,
      _ => at.dx,
    };
    painter.paint(canvas, Offset(dx, at.dy - painter.height + 3));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.active != active ||
      old.geometry.data != geometry.data ||
      old.geometry.size != geometry.size ||
      old.colors != colors;
}
