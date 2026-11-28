import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_field_frame.dart';
import 'mb_icon.dart';
import 'mb_select_field.dart';
import 'mb_text_field.dart';

/// A select for long lists: looks like [MbSelectField], and opens a sheet with
/// a search box. Use it where a state can have hundreds of choices.
class MbSearchSelectField<T> extends StatelessWidget {
  const MbSearchSelectField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.searchHint,
    this.label,
    this.icon,
    this.helper,
    this.error,
  });

  final List<MbSelectItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String searchHint;
  final String? label;
  final MbIcons? icon;
  final String? helper;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final selected = items.where((i) => i.value == value).firstOrNull;
    return Semantics(
      button: true,
      label: label,
      child: MbFieldFrame(
        label: label,
        helper: helper,
        error: error,
        onTap: onChanged == null || items.isEmpty ? null : () => _open(context),
        child: Row(
          children: [
            if (icon != null) ...[
              MbIcon(icon!, size: 18, color: c.inkMuted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  selected?.label ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.fieldInput.copyWith(color: c.ink),
                ),
              ),
            ),
            MbIcon(MbIcons.chevronDown, size: 18, color: c.inkMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<MbSelectItem<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => _SearchSheet<T>(
        items: items,
        selected: value,
        searchHint: searchHint,
      ),
    );
    if (picked != null && picked.value != value) onChanged?.call(picked.value);
  }
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.items,
    required this.selected,
    required this.searchHint,
  });

  final List<MbSelectItem<T>> items;
  final T? selected;
  final String searchHint;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.items
        : [
            for (final i in widget.items)
              if (i.label.toLowerCase().contains(q)) i,
          ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(MbSpacing.s4),
              child: MbTextField(
                hint: widget.searchHint,
                icon: MbIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final item = visible[i];
                  return ListTile(
                    dense: true,
                    selected: item.value == widget.selected,
                    title: Text(
                      item.label,
                      style: t.body.copyWith(color: c.ink),
                    ),
                    onTap: () => Navigator.of(context).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
