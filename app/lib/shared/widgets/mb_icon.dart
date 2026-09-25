import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mb_icons.dart';

export 'mb_icons.dart';

/// A MolBhav line icon. Takes the ambient [IconTheme] colour unless [color]
/// is given. Hidden from screen readers unless [semanticLabel] is set.
class MbIcon extends StatelessWidget {
  const MbIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
    this.semanticLabel,
  });

  final MbIcons icon;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color!;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">${icon.svgBody}</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: resolved),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
