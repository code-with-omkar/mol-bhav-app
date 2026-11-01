import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_button.dart';
import 'mb_field_frame.dart';
import 'mb_icon.dart';
import 'mb_text_field.dart';

/// A dropdown that picks several entries from a searchable list: tap the
/// field, tick entries, Apply. Nothing selected means "All". Disabled when
/// [options] is empty or [enabled] is false.
class MbMultiSelectField extends StatelessWidget {
  const MbMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final bool enabled;

  /// The new selection; empty = all.
  final ValueChanged<Set<String>> onChanged;

  bool get _usable => enabled && options.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;

    final summary = selected.isEmpty
        ? l10n.filterAllOption
        : selected.length <= 2
        ? selected.join(', ')
        : l10n.filterSelectedCount(selected.length);

    return Semantics(
      button: true,
      enabled: _usable,
      label: label,
      child: MbFieldFrame(
        label: label,
        onTap: _usable ? () => _open(context) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.fieldInput.copyWith(
                  color: _usable ? c.ink : c.inkMuted,
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
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) =>
          _MultiSelectSheet(title: label, options: options, initial: selected),
    );
    if (result != null) onChanged(result);
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<String> options;
  final Set<String> initial;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _selected = {...widget.initial};
  String _query = '';

  List<String> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (o.toLowerCase().contains(q)) o,
    ];
  }

  void _toggle(String option) => setState(
    () => _selected.contains(option)
        ? _selected.remove(option)
        : _selected.add(option),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final visible = _visible;

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
              padding: const EdgeInsets.fromLTRB(
                MbSpacing.s4,
                MbSpacing.s4,
                MbSpacing.s4,
                MbSpacing.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: t.title.copyWith(color: c.ink),
                    ),
                  ),
                  Text(
                    _selected.isEmpty
                        ? l10n.filterAllOption
                        : l10n.filterSelectedCount(_selected.length),
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s4),
              child: MbTextField(
                hint: l10n.filterSearchHint,
                icon: MbIcons.search,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s2),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: Text(l10n.clearSelectionAction),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, i) => CheckboxListTile(
                  value: _selected.contains(visible[i]),
                  onChanged: (_) => _toggle(visible[i]),
                  title: Text(visible[i], style: t.body.copyWith(color: c.ink)),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(MbSpacing.s4),
                child: MbButton(
                  label: l10n.applyAction,
                  block: true,
                  onPressed: () => Navigator.of(context).pop({..._selected}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
