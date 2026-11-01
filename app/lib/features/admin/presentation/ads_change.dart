import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/admin_ads.dart';
import 'admin_stat_card.dart';

AdminTrend _trend(double delta) => delta > 0.05
    ? AdminTrend.up
    : delta < -0.05
    ? AdminTrend.down
    : AdminTrend.flat;

String _signed(double value) =>
    '${value > 0.05 ? '+' : ''}${NumberFormat('0.0').format(value)}';

/// How [current] moved from [previous], in percent. Null when there is no
/// earlier figure to compare with; "New" when it was zero and is not now.
AdminChange? countChange(BuildContext context, num current, num? previous) {
  if (previous == null) return null;
  final change = percentChange(current, previous);
  if (change == null) {
    return current > 0
        ? AdminChange(context.l10n.adminAdsChangeNew, AdminTrend.up)
        : null;
  }
  return AdminChange('${_signed(change)}%', _trend(change));
}

/// How a rate (already a percent) moved, in percentage points.
AdminChange? rateChange(
  BuildContext context,
  double current,
  double? previous,
) {
  if (previous == null) return null;
  final points = current - previous;
  return AdminChange(
    context.l10n.adminAdsChangePoints(_signed(points)),
    _trend(points),
  );
}
