import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'formatters.dart';

extension TimestampText on BuildContext {
  String get _locale => Localizations.localeOf(this).languageCode;

  /// `Today, 09:45 AM`, `Yesterday, 06:10 PM` or `16 Sep, 09:45 AM`.
  String timestamp(DateTime time) {
    final clock = formatClock(time, _locale);
    return switch (relativeDay(time)) {
      RelativeDay.today => l10n.timeToday(clock),
      RelativeDay.yesterday => l10n.timeYesterday(clock),
      RelativeDay.earlier => l10n.timeOnDate(
        formatDayMonth(time, _locale),
        clock,
      ),
    };
  }

  /// `Updated today, 10:15 AM`.
  String updatedAt(DateTime time) => l10n.updatedAt(timestamp(time));

  String dateRange(DateTime start, DateTime end) =>
      formatDateRange(start, end, _locale);
}
