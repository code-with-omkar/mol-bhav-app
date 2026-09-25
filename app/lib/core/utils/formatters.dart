import 'package:intl/intl.dart';

final _inrWhole = NumberFormat('#,##,##0', 'en_IN');
final _inrDecimal = NumberFormat('#,##,##0.00', 'en_IN');

/// Indian digit grouping without the ₹ sign: 100000 → `1,00,000`,
/// 28.4 → `28.40`.
String formatIndian(num value) {
  final isWhole = value == value.roundToDouble();
  return isWhole ? _inrWhole.format(value) : _inrDecimal.format(value);
}

/// ₹ with Indian grouping: 58200 → `₹58,200`.
String formatInr(num value) => '₹${formatIndian(value)}';

/// `09:45 AM` in the given locale.
String formatClock(DateTime time, String locale) =>
    DateFormat('hh:mm a', locale).format(time);

/// `16 Sep` in the given locale.
String formatDayMonth(DateTime date, String locale) =>
    DateFormat('d MMM', locale).format(date);

/// `16–22 Sep`, or `28 Aug – 3 Sep` across months.
String formatDateRange(DateTime start, DateTime end, String locale) {
  if (start.month == end.month) {
    return '${start.day}–${formatDayMonth(end, locale)}';
  }
  return '${formatDayMonth(start, locale)} – ${formatDayMonth(end, locale)}';
}

enum RelativeDay { today, yesterday, earlier }

RelativeDay relativeDay(DateTime time, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(time);
  if (day == today) return RelativeDay.today;
  if (day == today.subtract(const Duration(days: 1))) {
    return RelativeDay.yesterday;
  }
  return RelativeDay.earlier;
}

abstract final class DateUtils {
  static DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
}
