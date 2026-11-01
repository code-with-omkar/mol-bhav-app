import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_field_frame.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/markets_entities.dart';

/// Which markets to compare: always one field ("5 of 23 markets") that opens a
/// searchable list. It looks the same for every product — switching to one
/// with only a few markets must not turn it into a row of chips — and a long
/// APMC list never pushes the prices off the screen.
class MarketPicker extends StatelessWidget {
  const MarketPicker({
    super.key,
    required this.markets,
    required this.selected,
    required this.onChanged,
  });

  final List<MarketRef> markets;
  final Set<String> selected;

  /// Never called with an empty set.
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final names = [
      for (final m in markets)
        if (selected.contains(m.id)) m.name,
    ];
    return Semantics(
      button: true,
      label: l10n.marketsLabel,
      child: MbFieldFrame(
        onTap: () => _open(context),
        child: Row(
          children: [
            MbIcon(MbIcons.market, size: 18, color: c.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.comparisonMarketsSelected(
                      selected.length,
                      markets.length,
                    ),
                    style: t.body.copyWith(color: c.ink),
                  ),
                  if (names.isNotEmpty)
                    Text(
                      names.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption.copyWith(color: c.inkMuted),
                    ),
                ],
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
      builder: (_) => _MarketSheet(markets: markets, initial: selected),
    );
    if (result != null && result.isNotEmpty && !_same(result, selected)) {
      onChanged(result);
    }
  }

  static bool _same(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

class _MarketSheet extends StatefulWidget {
  const _MarketSheet({required this.markets, required this.initial});

  final List<MarketRef> markets;
  final Set<String> initial;

  @override
  State<_MarketSheet> createState() => _MarketSheetState();
}

class _MarketSheetState extends State<_MarketSheet> {
  late final Set<String> _selected = {...widget.initial};
  String _query = '';

  List<MarketRef> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.markets;
    return [
      for (final m in widget.markets)
        if (m.name.toLowerCase().contains(q)) m,
    ];
  }

  void _toggle(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final visible = _visible;
    final allVisibleSelected =
        visible.isNotEmpty && visible.every((m) => _selected.contains(m.id));

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
                      l10n.comparisonChooseMarkets,
                      style: t.title.copyWith(color: c.ink),
                    ),
                  ),
                  Text(
                    l10n.comparisonMarketsSelected(
                      _selected.length,
                      widget.markets.length,
                    ),
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s4),
              child: MbTextField(
                hint: l10n.searchMarketsHint,
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
                    onPressed: visible.isEmpty
                        ? null
                        : () => setState(() {
                            if (allVisibleSelected) {
                              _selected.removeAll(visible.map((m) => m.id));
                            } else {
                              _selected.addAll(visible.map((m) => m.id));
                            }
                          }),
                    child: Text(
                      allVisibleSelected
                          ? l10n.clearSelectionAction
                          : l10n.selectAllAction,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final m = visible[i];
                  return CheckboxListTile(
                    value: _selected.contains(m.id),
                    onChanged: (_) => _toggle(m.id),
                    title: Text(m.name, style: t.body.copyWith(color: c.ink)),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(MbSpacing.s4),
                child: MbButton(
                  label: l10n.applyAction,
                  block: true,
                  // At least one market has to stay selected.
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop({..._selected}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
