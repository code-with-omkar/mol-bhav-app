import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';

/// Resting card (`.mb-card`): `surface-card`, hairline border, `radius-lg`.
class MbCard extends StatelessWidget {
  const MbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MbSpacing.s4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

/// Sticky bottom CTA area (`.mb-footer`).
class MbFooter extends StatelessWidget {
  const MbFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: MbSpacing.s6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MbSpacing.s4,
            MbSpacing.s3,
            MbSpacing.s4,
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Screen title block: `h1` with an optional muted lead line.
class MbPageHeading extends StatelessWidget {
  const MbPageHeading({super.key, required this.title, this.lead});

  final String title;
  final Widget? lead;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.mbText.h1.copyWith(color: c.ink)),
        ),
        if (lead != null) ...[const SizedBox(height: 4), lead!],
      ],
    );
  }
}

/// Inline green text action (`.mb-sech-action`): "Change", "View All".
class MbTextLink extends StatelessWidget {
  const MbTextLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Text(
            label,
            style: context.mbText.link.copyWith(
              color: context.mbColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
