import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/theme/app_theme.dart';

/// Type-only stand-in for the MolBhav logo until the logo files are
/// supplied. Never redraw or approximate the mark here.
class MbWordmark extends StatelessWidget {
  const MbWordmark({
    super.key,
    this.size = 32,
    this.descriptor = true,
    this.onHero = false,
  });

  /// Font size of the name; the descriptor scales with it.
  final double size;
  final bool descriptor;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final ink = onHero ? c.inkOnHero : c.ink;
    final descSize = (size * 0.36).roundToDouble().clamp(11.0, double.infinity);

    // The logo file (mark + name + descriptor) has navy type, so it is used
    // on light grounds only; the hero band keeps the type-only wordmark.
    if (descriptor && !onHero) {
      return Image.asset(
        'assets/images/molbhav_logo.png',
        height: size * 1.6,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        semanticLabel: '${Brand.name} — ${Brand.descriptor}',
      );
    }

    return Semantics(
      label: descriptor ? '${Brand.name} — ${Brand.descriptor}' : Brand.name,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Brand.name,
              style: t.wordmark.copyWith(
                fontSize: size,
                height: 1,
                letterSpacing: -0.02 * size,
                color: ink,
              ),
            ),
            if (descriptor) ...[
              SizedBox(height: descSize * 0.35),
              Text(
                Brand.descriptor,
                style: t.wordmarkDescriptor.copyWith(
                  fontSize: descSize,
                  height: 1.2,
                  color: onHero
                      ? c.inkOnHero.withValues(alpha: 0.85)
                      : c.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
