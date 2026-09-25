import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';

/// Shared chrome for [MbTextField] and [MbSelectField]: label above, a 48px
/// outlined box, helper or error text below.
class MbFieldFrame extends StatelessWidget {
  const MbFieldFrame({
    super.key,
    required this.child,
    this.label,
    this.helper,
    this.error,
    this.focused = false,
    this.onTap,
  });

  final Widget child;
  final String? label;
  final String? helper;
  final String? error;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final hasError = error != null;
    final borderColor = hasError
        ? c.priceUp
        : focused
        ? c.primary
        : c.borderStrong;
    final note = error ?? helper;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: t.fieldLabel.copyWith(color: c.ink)),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s3),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(MbRadius.sm),
              border: Border.all(color: borderColor),
              boxShadow: focused && !hasError
                  ? [BoxShadow(color: c.primary, spreadRadius: 1)]
                  : null,
            ),
            child: child,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(
            note,
            style: t.caption.copyWith(color: hasError ? c.priceUp : c.inkMuted),
          ),
        ],
      ],
    );
  }
}
