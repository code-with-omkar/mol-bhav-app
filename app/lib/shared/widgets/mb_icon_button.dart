import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'mb_icon.dart';

/// 40px round icon button (`.mb-iconbtn`) with a 48px tap target.
class MbIconButton extends StatelessWidget {
  const MbIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final MbIcons icon;

  /// Accessible name and tooltip.
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: MbIcon(icon, size: 22, color: color ?? c.ink),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        highlightColor: c.surfaceGreenSoft,
        hoverColor: c.surfaceGreenSoft,
      ),
    );
  }
}
