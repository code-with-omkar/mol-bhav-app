import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Applies the brand font families to a base style.
///
/// Font families are resolved per weight (google_fonts registers one family
/// per weight), so widgets must only `copyWith` colour, size or spacing —
/// never `fontWeight`. Add a named style below when a new weight is needed.
typedef MbFontResolver = TextStyle Function(TextStyle base, {bool deva});

/// Manrope for Latin UI with Noto Sans Devanagari fallback (Hindi, Marathi);
/// Noto Sans Devanagari for Devanagari-first copy such as the tagline.
TextStyle googleFontResolver(TextStyle base, {bool deva = false}) {
  if (deva) return GoogleFonts.notoSansDevanagari(textStyle: base);
  final devaFallback = GoogleFonts.notoSansDevanagari(
    fontWeight: base.fontWeight,
  ).fontFamily;
  return GoogleFonts.manrope(textStyle: base)
      .copyWith(fontFamilyFallback: [?devaFallback]);
}

/// Keeps the platform font. Used by tests, which must not fetch fonts.
TextStyle platformFontResolver(TextStyle base, {bool deva = false}) => base;

/// MolBhav type scale (design system `tokens.json` → `type`) plus the
/// component styles defined by the component stylesheet.
@immutable
class MbTypography extends ThemeExtension<MbTypography> {
  const MbTypography._({
    required this.display,
    required this.h1,
    required this.h2,
    required this.title,
    required this.priceLg,
    required this.price,
    required this.body,
    required this.caption,
    required this.label,
    required this.taglineHi,
    required this.bodyHi,
    required this.appBarTitle,
    required this.button,
    required this.buttonSm,
    required this.buttonLg,
    required this.fieldLabel,
    required this.fieldInput,
    required this.fieldPlaceholder,
    required this.chip,
    required this.link,
    required this.cardSubtitle,
    required this.otpDigit,
    required this.wordmark,
    required this.wordmarkDescriptor,
    required this.rowName,
    required this.micro,
    required this.microStrong,
    required this.tab,
    required this.change,
    required this.valueLg,
    required this.valueMd,
    required this.stat,
    required this.nav,
    required this.axis,
  });

  factory MbTypography.resolve(MbFontResolver resolve) {
    TextStyle s(
      double size,
      double lineHeight,
      FontWeight weight, {
      double letterSpacingEm = 0,
      bool tabular = false,
      bool deva = false,
    }) {
      return resolve(
        TextStyle(
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          letterSpacing: letterSpacingEm * size,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        deva: deva,
      );
    }

    return MbTypography._(
      display: s(40, 44, FontWeight.w800, letterSpacingEm: -0.02),
      h1: s(24, 32, FontWeight.w700, letterSpacingEm: -0.01),
      h2: s(18, 26, FontWeight.w700),
      title: s(16, 22, FontWeight.w700),
      priceLg: s(24, 30, FontWeight.w800, tabular: true),
      price: s(15, 20, FontWeight.w700, tabular: true),
      body: s(14, 20, FontWeight.w500),
      caption: s(12, 16, FontWeight.w500),
      label: s(11, 14, FontWeight.w600),
      taglineHi: s(24, 36, FontWeight.w700, deva: true),
      bodyHi: s(15, 24, FontWeight.w500, deva: true),
      appBarTitle: s(17, 24, FontWeight.w700),
      button: s(14, 20, FontWeight.w700),
      buttonSm: s(12, 16, FontWeight.w700),
      buttonLg: s(15, 22, FontWeight.w700),
      fieldLabel: s(13, 18, FontWeight.w600),
      fieldInput: s(15, 22, FontWeight.w600, tabular: true),
      fieldPlaceholder: s(15, 22, FontWeight.w500),
      chip: s(13, 18, FontWeight.w600),
      link: s(12, 16, FontWeight.w700),
      cardSubtitle: s(12, 17, FontWeight.w500),
      otpDigit: s(22, 28, FontWeight.w800, tabular: true),
      wordmark: s(32, 32, FontWeight.w800, letterSpacingEm: -0.02),
      wordmarkDescriptor: s(12, 14, FontWeight.w500),
      rowName: s(14, 20, FontWeight.w600),
      micro: s(11, 14, FontWeight.w500),
      microStrong: s(11, 15, FontWeight.w700),
      tab: s(12, 16, FontWeight.w600),
      change: s(12, 16, FontWeight.w700, tabular: true),
      valueLg: s(28, 34, FontWeight.w800, tabular: true),
      valueMd: s(20, 28, FontWeight.w800, tabular: true),
      stat: s(16, 22, FontWeight.w800, tabular: true),
      nav: s(10.5, 14, FontWeight.w600),
      axis: s(10, 13, FontWeight.w500, tabular: true),
    );
  }

  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle title;
  final TextStyle priceLg;
  final TextStyle price;
  final TextStyle body;
  final TextStyle caption;
  final TextStyle label;
  final TextStyle taglineHi;
  final TextStyle bodyHi;
  final TextStyle appBarTitle;
  final TextStyle button;
  final TextStyle buttonSm;
  final TextStyle buttonLg;
  final TextStyle fieldLabel;
  final TextStyle fieldInput;
  final TextStyle fieldPlaceholder;
  final TextStyle chip;
  final TextStyle link;
  final TextStyle cardSubtitle;
  final TextStyle otpDigit;
  final TextStyle wordmark;
  final TextStyle wordmarkDescriptor;

  /// Row and list-item titles (14/20 600).
  final TextStyle rowName;

  /// 11px meta: times, channels.
  final TextStyle micro;

  /// 11px bold: source names.
  final TextStyle microStrong;
  final TextStyle tab;

  /// Signed price change (tabular).
  final TextStyle change;

  /// Highlight-panel and plan figures.
  final TextStyle valueLg;
  final TextStyle valueMd;

  /// Stat figures and plan names (16/22 800).
  final TextStyle stat;
  final TextStyle nav;

  /// Chart axis labels.
  final TextStyle axis;

  @override
  MbTypography copyWith() => this;

  @override
  MbTypography lerp(MbTypography? other, double t) => t < 0.5 ? this : other!;
}
