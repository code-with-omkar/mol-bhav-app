import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_chip_group.dart';
import 'mb_icons.dart';
import 'mb_text_field.dart';

/// One way to order a list.
class MbSort<T> {
  const MbSort(this.label, this.compare);

  final String label;

  /// `null` keeps the order the list arrived in.
  final Comparator<T>? compare;
}

/// One way to narrow a list.
class MbFilter<T> {
  const MbFilter(this.label, this.test);

  final String label;
  final bool Function(T item) test;
}

/// Search, sort and filter controls above a list that is already loaded: all of
/// it happens on the phone, so it answers as you type and works offline.
///
/// The controls appear once there are [minItems] to look through; [builder]
/// draws whatever is left.
class MbFilterableList<T> extends StatefulWidget {
  const MbFilterableList({
    super.key,
    required this.items,
    required this.builder,
    this.searchText,
    this.searchHint,
    this.sorts = const [],
    this.filters = const [],
    this.minItems = 4,
  });

  final List<T> items;
  final Widget Function(BuildContext context, List<T> visible) builder;

  /// What the search box matches; `null` shows no search box.
  final String Function(T item)? searchText;
  final String? searchHint;

  /// The first one is the starting order.
  final List<MbSort<T>> sorts;

  /// Shown as chips after "All". A filter nothing matches is left out.
  final List<MbFilter<T>> filters;

  final int minItems;

  @override
  State<MbFilterableList<T>> createState() => _MbFilterableListState<T>();
}

class _MbFilterableListState<T> extends State<MbFilterableList<T>> {
  String _query = '';
  int _sort = 0;

  /// The chosen filter's label (labels survive a reload; positions may not).
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final show = widget.items.length >= widget.minItems;

    final filters = [
      for (final f in widget.filters)
        if (widget.items.any(f.test)) f,
    ];
    final filter = filters.where((f) => f.label == _filter).firstOrNull;
    final sort = _sort < widget.sorts.length ? widget.sorts[_sort] : null;
    final query = _query.trim().toLowerCase();
    final text = widget.searchText;

    var visible = widget.items;
    if (show) {
      visible = [
        for (final item in widget.items)
          if ((filter == null || filter.test(item)) &&
              (query.isEmpty ||
                  text == null ||
                  text(item).toLowerCase().contains(query)))
            item,
      ];
      final compare = sort?.compare;
      if (compare != null) visible.sort(compare);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (show) ...[
          if (text != null) ...[
            MbTextField(
              key: const ValueKey('list-search'),
              hint: widget.searchHint ?? l10n.search,
              icon: MbIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: MbSpacing.s2),
          ],
          if (widget.sorts.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<int>(
                key: const ValueKey('list-sort'),
                tooltip: l10n.sortLabel,
                initialValue: _sort,
                onSelected: (i) => setState(() => _sort = i),
                itemBuilder: (_) => [
                  for (final (i, s) in widget.sorts.indexed)
                    PopupMenuItem(value: i, child: Text(s.label)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert, size: 18, color: c.primaryText),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${l10n.sortLabel}: ${sort?.label ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          style: t.chip.copyWith(color: c.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (filters.isNotEmpty) ...[
            MbChipGroup<String>.single(
              value: filter?.label ?? '',
              onChanged: (label) => setState(() => _filter = label),
              options: [
                MbChipOption(value: '', label: l10n.filterAll),
                for (final f in filters)
                  MbChipOption(value: f.label, label: f.label),
              ],
            ),
            const SizedBox(height: MbSpacing.s3),
          ],
        ],
        if (show && visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MbSpacing.s4),
            child: Text(
              l10n.noMatches,
              textAlign: TextAlign.center,
              style: t.body.copyWith(color: c.inkMuted),
            ),
          )
        else
          widget.builder(context, visible),
      ],
    );
  }
}
