import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_icon.dart';

class MbChipOption<T> {
  const MbChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Selectable pills for short option sets (business type, markets, alert
/// condition, language). Selected chips get `surface-green`, a `primary`
/// border and a check — never colour alone.
class MbChipGroup<T> extends StatelessWidget {
  /// One selected value at a time.
  MbChipGroup.single({
    super.key,
    required this.options,
    required T? value,
    required ValueChanged<T> onChanged,
    this.semanticLabel,
  }) : _isSelected = ((v) => v == value),
       _onTap = onChanged;

  /// Any number of selected values; [onChanged] receives the new set.
  MbChipGroup.multiple({
    super.key,
    required this.options,
    required Set<T> values,
    required ValueChanged<Set<T>> onChanged,
    this.semanticLabel,
  }) : _isSelected = values.contains,
       _onTap = ((v) => onChanged(
         values.contains(v) ? ({...values}..remove(v)) : {...values, v},
       ));

  final List<MbChipOption<T>> options;
  final String? semanticLabel;
  final bool Function(T value) _isSelected;
  final ValueChanged<T> _onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        spacing: MbSpacing.s2,
        runSpacing: MbSpacing.s2,
        children: [
          for (final option in options)
            _Chip(
              label: option.label,
              selected: _isSelected(option.value),
              onTap: () => _onTap(option.value),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final foreground = selected ? c.primaryText : c.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.surfaceGreen : c.surfaceCard,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.primary : c.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  MbIcon(
                    MbIcons.check,
                    size: 14,
                    strokeWidth: 2.5,
                    color: foreground,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: context.mbText.chip.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
