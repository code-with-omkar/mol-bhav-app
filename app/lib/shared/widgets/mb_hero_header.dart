import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/brand.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_icon.dart';
import 'mb_panels.dart';
import 'mb_wordmark.dart';

/// Home band on `hero`: wordmark, alerts bell with unread dot, avatar,
/// Hindi tagline, greeting and name. The content sheet below overlaps it by
/// [overlap] with a `radius-xl` top.
class MbHeroHeader extends StatelessWidget {
  const MbHeroHeader({
    super.key,
    required this.name,
    required this.greeting,
    required this.alertsLabel,
    this.subtitle,
    this.unread = false,
    this.onAlerts,
  });

  static const overlap = MbSpacing.s6;

  final String name;
  final String greeting;
  final String alertsLabel;
  final String? subtitle;
  final bool unread;
  final VoidCallback? onAlerts;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final onHero = c.inkOnHero;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: c.hero,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeroArtPainter(c.molGreen)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MbSpacing.s4,
                  MbSpacing.s2,
                  MbSpacing.s4,
                  MbSpacing.s8 + overlap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          const MbWordmark(
                            size: 22,
                            descriptor: false,
                            onHero: true,
                          ),
                          const Spacer(),
                          _Bell(
                            label: alertsLabel,
                            unread: unread,
                            onPressed: onAlerts,
                          ),
                          const SizedBox(width: MbSpacing.s2),
                          MbAvatar(name: name),
                        ],
                      ),
                    ),
                    const SizedBox(height: MbSpacing.s2),
                    Text(
                      Brand.taglineHi,
                      style: t.taglineHi.copyWith(
                        fontSize: 17,
                        height: 26 / 17,
                        color: onHero,
                      ),
                    ),
                    const SizedBox(height: MbSpacing.s5),
                    Text(
                      greeting,
                      style: t.body.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                        color: onHero.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(name, style: t.valueMd.copyWith(color: onHero)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          subtitle!,
                          style: t.cardSubtitle.copyWith(
                            color: onHero.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.label, required this.unread, this.onPressed});

  final String label;
  final bool unread;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: label,
          icon: MbIcon(MbIcons.alert, size: 22, color: c.inkOnHero),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(40),
            minimumSize: const Size.square(40),
            padding: EdgeInsets.zero,
            highlightColor: c.inkOnHero.withValues(alpha: 0.12),
          ),
        ),
        if (unread)
          Positioned(
            top: 13,
            right: 14,
            child: IgnorePointer(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.bhavAmber,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.hero, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The single rising Mol Green line standing in for the board's photograph.
class _HeroArtPainter extends CustomPainter {
  _HeroArtPainter(this.color);

  final Color color;

  static const _points = [
    Offset(170, 170),
    Offset(220, 150),
    Offset(250, 158),
    Offset(290, 120),
    Offset(320, 128),
    Offset(390, 60),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390, sy = size.height / 200;
    final path = Path()
      ..addPolygon([
        for (final p in _points) Offset(p.dx * sx, p.dy * sy),
      ], false);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HeroArtPainter old) => old.color != color;
}
