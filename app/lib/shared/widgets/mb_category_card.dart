import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_icon.dart';

/// Category palette tie-in: Agriculture `green`, Construction `amber`,
/// other live categories `navy`, not-yet-launched ones `grey`.
enum MbCategoryTone { green, amber, navy, grey }

/// Procurement category row (the "Select Category" list). Shows a check when
/// [selected], a chevron otherwise; `onTap: null` renders it disabled.
class MbCategoryRow extends StatelessWidget {
  const MbCategoryRow({
    super.key,
    required this.title,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final MbIcons icon;
  final MbCategoryTone tone;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final enabled = onTap != null;
    final (Color discBg, Color discFg) = switch (tone) {
      MbCategoryTone.green => (c.primary, c.onPrimary),
      MbCategoryTone.amber => (c.accent, c.onAccent),
      MbCategoryTone.navy => (c.hero, c.inkOnHero),
      MbCategoryTone.grey => (c.surfaceGreenSoft, c.inkMuted),
    };
    final radius = BorderRadius.circular(MbRadius.md);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              ...c.shadowCard,
              if (selected) BoxShadow(color: c.primary, spreadRadius: 1),
            ],
          ),
          child: Material(
            color: c.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: selected ? c.primary : c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(MbSpacing.s3),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: discBg,
                        shape: BoxShape.circle,
                      ),
                      child: MbIcon(icon, color: discFg),
                    ),
                    const SizedBox(width: MbSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.title.copyWith(color: c.ink)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: t.cardSubtitle.copyWith(color: c.inkMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: MbSpacing.s3),
                    if (selected)
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                        ),
                        child: MbIcon(
                          MbIcons.check,
                          size: 16,
                          strokeWidth: 3,
                          color: c.onPrimary,
                        ),
                      )
                    else
                      MbIcon(MbIcons.chevronRight, size: 18, color: c.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Category tile for the 2-up grid on Home ("What are you buying today?").
class MbCategoryTile extends StatelessWidget {
  const MbCategoryTile({
    super.key,
    required this.title,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final MbIcons icon;
  final MbCategoryTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final (Color tileBg, Color discBg, Color discFg) = switch (tone) {
      MbCategoryTone.green => (c.surfaceGreen, c.primary, c.onPrimary),
      MbCategoryTone.amber => (c.surfaceAmber, c.accent, c.onAccent),
      MbCategoryTone.navy => (c.surfaceCard, c.hero, c.inkOnHero),
      MbCategoryTone.grey => (c.surfaceCard, c.surfaceGreenSoft, c.inkMuted),
    };
    final tinted = tone == MbCategoryTone.green || tone == MbCategoryTone.amber;
    final radius = BorderRadius.circular(MbRadius.lg);

    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: tinted ? null : c.shadowCard,
        ),
        child: Material(
          color: tileBg,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: tinted ? Colors.transparent : c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 164),
              child: Padding(
                padding: const EdgeInsets.all(MbSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: discBg,
                        shape: BoxShape.circle,
                      ),
                      child: MbIcon(icon, color: discFg),
                    ),
                    const SizedBox(height: MbSpacing.s3),
                    Text(
                      title,
                      style: t.title.copyWith(
                        fontSize: 17,
                        height: 24 / 17,
                        color: c.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: t.cardSubtitle.copyWith(color: c.inkMuted),
                      ),
                    ],
                    const SizedBox(height: MbSpacing.s3),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: MbIcon(
                        MbIcons.chevronRight,
                        size: 18,
                        color: c.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
