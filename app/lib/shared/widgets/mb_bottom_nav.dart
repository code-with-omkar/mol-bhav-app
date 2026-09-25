import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_icon.dart';

class MbNavItem {
  const MbNavItem({required this.icon, required this.label});

  final MbIcons icon;
  final String label;
}

/// App bottom navigation: Home, Markets, Watchlist, Opportunities, More.
class MbBottomNav extends StatelessWidget {
  const MbBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<MbNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceCard,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: c.shadowRaised,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: MbSpacing.s4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MbSpacing.s1,
            MbSpacing.s2,
            MbSpacing.s1,
            0,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MbNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final color = active ? c.primaryText : c.inkMuted;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MbRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MbIcon(item.icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.mbText.nav.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
