import 'package:flutter/widgets.dart';

/// Splits [rows] into groups of [every] and puts an ad between consecutive
/// groups — never before the first or after the last, so a short list gets no
/// ad and a long one gets one per [every] rows, up to [maxAds] (a long list in
/// a non-lazy column would otherwise request ads nobody scrolls to). Rows stay
/// inside their own visual group instead of an ad breaking one apart.
List<Widget> interleaveAds({
  required List<Widget> rows,
  required int every,
  required Widget Function(List<Widget> rows) group,
  required Widget Function(int index) ad,
  int maxAds = 2,
  Widget spacing = const SizedBox.shrink(),
}) {
  assert(every > 0, 'every must be positive');
  final result = <Widget>[];
  var adIndex = 0;
  for (var start = 0; start < rows.length; start += every) {
    final end = start + every < rows.length ? start + every : rows.length;
    if (start > 0) {
      result.add(spacing);
      if (adIndex < maxAds) {
        result
          ..add(ad(adIndex++))
          ..add(spacing);
      }
    }
    result.add(group(rows.sublist(start, end)));
  }
  return result;
}
