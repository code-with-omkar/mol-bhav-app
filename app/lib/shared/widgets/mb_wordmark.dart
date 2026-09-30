import 'package:flutter/material.dart';

import '../../core/brand.dart';

/// MolBhav logo. The full lockup has dark type, so on the hero band only the
/// mark is shown.
class MbWordmark extends StatelessWidget {
  const MbWordmark({
    super.key,
    this.size = 32,
    this.onHero = false,
    this.alignment = Alignment.centerLeft,
  });

  static const logoAsset = 'assets/branding/molbhav_logo.png';
  static const markAsset = 'assets/branding/molbhav_mark.png';

  final double size;
  final bool onHero;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onHero ? markAsset : logoAsset,
      height: onHero ? size * 1.4 : size * 1.6,
      fit: BoxFit.contain,
      alignment: alignment,
      semanticLabel: '${Brand.name} — ${Brand.descriptor}',
    );
  }
}
