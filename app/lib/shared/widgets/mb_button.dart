import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'mb_icon.dart';

enum MbButtonVariant { primary, secondary, ghost }

enum MbButtonSize { sm, md, lg }

/// Pill button. `primary` is the one main action per view; `secondary` is
/// outlined; `ghost` is a green text action.
class MbButton extends StatelessWidget {
  const MbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MbButtonVariant.primary,
    this.size = MbButtonSize.md,
    this.block = false,
    this.icon,
    this.isLoading = false,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final MbButtonVariant variant;
  final MbButtonSize size;

  /// Stretch to the container width (sheet CTAs).
  final bool block;
  final MbIcons? icon;

  /// Shows a progress indicator and ignores taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final enabled = onPressed != null && !isLoading;

    final (
      Color background,
      Color foreground,
      Color borderColor,
    ) = switch (variant) {
      MbButtonVariant.primary => (c.primary, c.onPrimary, c.primary),
      MbButtonVariant.secondary => (
        c.surfaceCard,
        c.primaryText,
        c.borderStrong,
      ),
      MbButtonVariant.ghost => (
        Colors.transparent,
        c.primaryText,
        Colors.transparent,
      ),
    };
    final textStyle = switch (size) {
      MbButtonSize.sm => t.buttonSm,
      MbButtonSize.md => t.button,
      MbButtonSize.lg => t.buttonLg,
    };
    final double horizontal = variant == MbButtonVariant.ghost
        ? 8
        : switch (size) {
            MbButtonSize.sm => 14,
            MbButtonSize.md => 20,
            MbButtonSize.lg => 24,
          };
    final double vertical = switch (size) {
      MbButtonSize.sm => 7,
      MbButtonSize.md => 10,
      MbButtonSize.lg => 14,
    };
    final hover = variant == MbButtonVariant.primary
        ? c.primaryHover
        : c.surfaceGreenSoft;

    final Widget? leading = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : icon == null
        ? null
        : MbIcon(icon!, size: 18, color: foreground);

    final content = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            style: textStyle.copyWith(color: foreground),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: Material(
          color: background,
          shape: StadiumBorder(side: BorderSide(color: borderColor)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            hoverColor: hover,
            highlightColor: hover,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
