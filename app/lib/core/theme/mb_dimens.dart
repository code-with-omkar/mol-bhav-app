import 'package:flutter/widgets.dart';

/// Spacing scale (design system `spacing`).
abstract final class MbSpacing {
  /// Icon-to-text gap, arrow-to-value.
  static const double s1 = 4;

  /// Gap inside rows and chips; stacked meta lines.
  static const double s2 = 8;

  /// Gap between tiles; row vertical padding.
  static const double s3 = 12;

  /// Card padding; screen side gutter.
  static const double s4 = 16;

  /// Large tile padding.
  static const double s5 = 20;

  /// Between sections on a screen.
  static const double s6 = 24;

  /// Hero padding; major separations.
  static const double s8 = 32;

  /// Standard scrolling content padding (`.mb-pad`).
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(s4, s2, s4, s4);
}

/// Corner radii (design system `radius`).
abstract final class MbRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}
