import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_field_frame.dart';
import 'mb_icon.dart';

class MbSelectItem<T> {
  const MbSelectItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Select styled like [MbTextField], with an optional leading icon and a
/// chevron. Pass `onChanged: null` to disable it.
class MbSelectField<T> extends StatelessWidget {
  const MbSelectField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.helper,
    this.error,
  });

  final List<MbSelectItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? hint;
  final MbIcons? icon;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final enabled = onChanged != null;

    return MbFieldFrame(
      label: label,
      helper: helper,
      error: error,
      child: Row(
        children: [
          if (icon != null) ...[
            MbIcon(icon!, size: 18, color: c.inkMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Semantics(
              label: label,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  itemHeight: 48,
                  hint: hint == null
                      ? null
                      : Text(
                          hint!,
                          style: t.fieldPlaceholder.copyWith(color: c.inkMuted),
                        ),
                  icon: MbIcon(
                    MbIcons.chevronDown,
                    size: 18,
                    color: c.inkMuted,
                  ),
                  style: t.fieldInput.copyWith(color: c.ink),
                  dropdownColor: c.surfaceCard,
                  borderRadius: BorderRadius.circular(MbRadius.sm),
                  onChanged: enabled
                      ? (next) {
                          if (next != null) onChanged!(next);
                        }
                      : null,
                  items: [
                    for (final item in items)
                      DropdownMenuItem<T>(
                        value: item.value,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
