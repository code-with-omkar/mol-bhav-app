import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_icon.dart';
import 'mb_layout.dart';
import 'mb_price.dart';

/// The screen's one answer: potential difference, estimated cost, best
/// market. `green` or `amber`.
class MbHighlightPanel extends StatelessWidget {
  const MbHighlightPanel({
    super.key,
    required this.value,
    this.label,
    this.unit,
    this.caption,
    this.tone = MbTone.green,
    this.body,
  });

  final String value;
  final String? label;
  final String? unit;
  final String? caption;
  final MbTone tone;

  /// Explanation under a hairline (e.g. "How we calculated this").
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final amber = tone == MbTone.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MbSpacing.s4),
      decoration: BoxDecoration(
        color: amber ? c.surfaceAmberSoft : c.surfaceGreen,
        borderRadius: BorderRadius.circular(MbRadius.lg),
        border: amber ? Border.all(color: c.surfaceAmber) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(
              label!,
              style: t.fieldLabel.copyWith(
                color: amber ? c.accentText : c.primaryText,
              ),
            ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: t.body.copyWith(fontSize: 13, color: c.inkMuted),
                  ),
              ],
            ),
            style: t.valueLg.copyWith(color: c.ink),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: t.caption.copyWith(color: c.inkMuted)),
          ],
          if (body != null) ...[
            const SizedBox(height: MbSpacing.s3),
            Divider(height: 1, thickness: 1, color: c.border),
            const SizedBox(height: MbSpacing.s3),
            DefaultTextStyle(
              style: t.cardSubtitle.copyWith(
                height: 18 / 12,
                color: c.inkMuted,
              ),
              child: body!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Data provenance + freshness line. Every price surface carries one.
class MbSourceNote extends StatelessWidget {
  const MbSourceNote({super.key, this.source, this.updated});

  final String? source;
  final String? updated;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Row(
      children: [
        MbIcon(MbIcons.freshness, size: 14, color: c.inkMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (source != null)
                  TextSpan(
                    text: source,
                    style: t.microStrong.copyWith(color: c.inkMuted),
                  ),
                if (source != null && updated != null)
                  const TextSpan(text: ' · '),
                if (updated != null) TextSpan(text: updated),
              ],
            ),
            style: t.micro.copyWith(height: 15 / 11, color: c.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Section title with an optional green action ("View All").
class MbSectionHeader extends StatelessWidget {
  const MbSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.mbText.title.copyWith(color: context.mbColors.ink),
            ),
          ),
        ),
        if (actionLabel != null)
          MbTextLink(label: actionLabel!, onPressed: onAction),
      ],
    );
  }
}

class MbTabOption<T> {
  const MbTabOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill tabs for ranges (7D/30D/90D/1Y) and filters. [stretch] makes the
/// tabs share the width equally.
class MbSegmentedTabs<T> extends StatelessWidget {
  const MbSegmentedTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.stretch = false,
  });

  final List<MbTabOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final option in options)
        _Tab(
          label: option.label,
          selected: option.value == value,
          onTap: () => onChanged(option.value),
        ),
    ];
    if (stretch) {
      return Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: MbSpacing.s2),
            Expanded(child: tabs[i]),
          ],
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: MbSpacing.s2,
        runSpacing: MbSpacing.s2,
        children: tabs,
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.ink : c.surfaceCard,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.ink : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.mbText.tab.copyWith(
                color: selected ? c.surface : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// On/off switch (44×26, `primary` track when on).
class MbToggle extends StatelessWidget {
  const MbToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? c.primary : c.borderStrong,
            borderRadius: BorderRadius.circular(MbRadius.pill),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: c.surfaceCard,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Initials in a Bhav Amber disc.
class MbAvatar extends StatelessWidget {
  const MbAvatar({super.key, required this.name, this.size = 34});

  final String name;
  final double size;

  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p.characters.first.toUpperCase())
      .take(2)
      .join();

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.bhavAmber, shape: BoxShape.circle),
        child: Text(
          initialsOf(name),
          style: context.mbText.stat.copyWith(
            fontSize: 13,
            height: 1,
            color: c.marketNavy,
          ),
        ),
      ),
    );
  }
}

/// List row: icon disc, title/subtitle, optional value and trailing widget
/// (chevron by default when tappable).
class MbListItem extends StatelessWidget {
  const MbListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.iconTone = MbTone.neutral,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final MbIcons? icon;

  /// Custom leading widget (e.g. an avatar) instead of [icon].
  final Widget? leading;
  final MbTone iconTone;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final (Color discBg, Color discFg) = switch (iconTone) {
      MbTone.green => (c.surfaceGreen, c.primaryText),
      MbTone.amber => (c.surfaceAmber, c.accentText),
      MbTone.navy => (c.hero, c.bhavAmber),
      MbTone.neutral => (c.surfaceGreenSoft, danger ? c.priceUp : c.ink),
    };
    final trailingWidget =
        trailing ??
        (showChevron && onTap != null
            ? MbIcon(MbIcons.chevronRight, size: 18, color: c.inkMuted)
            : null);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: MbSpacing.s3,
        horizontal: MbSpacing.s4,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: MbSpacing.s3),
          ] else if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: discBg, shape: BoxShape.circle),
              child: MbIcon(icon!, size: 20, color: discFg),
            ),
            const SizedBox(width: MbSpacing.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.rowName.copyWith(color: danger ? c.priceUp : c.ink),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: t.caption.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: MbSpacing.s3),
            Text(value!, style: t.chip.copyWith(color: c.inkMuted)),
          ],
          if (trailingWidget != null) ...[
            const SizedBox(width: MbSpacing.s3),
            trailingWidget,
          ],
        ],
      ),
    );

    return Material(
      color: c.surfaceCard,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Stat cell: muted caption over a bold figure (Min / Modal / Max).
class MbStat extends StatelessWidget {
  const MbStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.mbText.caption.copyWith(color: c.inkMuted)),
        Text(value, style: context.mbText.stat.copyWith(color: c.ink)),
      ],
    );
  }
}
