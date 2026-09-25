import 'package:flutter/material.dart';

/// MolBhav colour tokens (design system `tokens.json`), light and dark.
///
/// Widgets read these through `context.mbColors`; never hardcode hex values
/// outside this file.
@immutable
class MbColors extends ThemeExtension<MbColors> {
  const MbColors({
    required this.molGreen,
    required this.marketNavy,
    required this.bhavAmber,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceGreen,
    required this.surfaceGreenSoft,
    required this.surfaceAmber,
    required this.surfaceAmberSoft,
    required this.hero,
    required this.ink,
    required this.inkMuted,
    required this.inkOnHero,
    required this.border,
    required this.borderStrong,
    required this.primary,
    required this.primaryHover,
    required this.onPrimary,
    required this.primaryText,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.priceUp,
    required this.priceDown,
    required this.focusRing,
    required this.shadowCard,
    required this.shadowRaised,
  });

  final Color molGreen;
  final Color marketNavy;
  final Color bhavAmber;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceGreen;
  final Color surfaceGreenSoft;
  final Color surfaceAmber;
  final Color surfaceAmberSoft;
  final Color hero;
  final Color ink;
  final Color inkMuted;
  final Color inkOnHero;
  final Color border;
  final Color borderStrong;
  final Color primary;
  final Color primaryHover;
  final Color onPrimary;
  final Color primaryText;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color priceUp;
  final Color priceDown;
  final Color focusRing;
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowRaised;

  static const _molGreen = Color(0xFF168447);
  static const _marketNavy = Color(0xFF172B2A);
  static const _bhavAmber = Color(0xFFF39A35);
  static const _warmWhite = Color(0xFFF7F8F5);

  static const light = MbColors(
    molGreen: _molGreen,
    marketNavy: _marketNavy,
    bhavAmber: _bhavAmber,
    surface: _warmWhite,
    surfaceCard: Color(0xFFFFFFFF),
    surfaceGreen: Color(0xFFE7F4E9),
    surfaceGreenSoft: Color(0xFFEDF3ED),
    surfaceAmber: Color(0xFFFEEED3),
    surfaceAmberSoft: Color(0xFFFEF7EA),
    hero: _marketNavy,
    ink: _marketNavy,
    inkMuted: Color(0xFF5C6660),
    inkOnHero: _warmWhite,
    border: Color(0xFFE3E7E3),
    borderStrong: Color(0xFF8A958F),
    primary: _molGreen,
    primaryHover: Color(0xFF126E3B),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF126E3B),
    accent: _bhavAmber,
    onAccent: _marketNavy,
    accentText: Color(0xFF8F4F07),
    priceUp: Color(0xFFB42323),
    priceDown: Color(0xFF126E3B),
    focusRing: _molGreen,
    shadowCard: [
      BoxShadow(color: Color(0x0F172B2A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x0F172B2A), offset: Offset(0, 4), blurRadius: 12),
    ],
    shadowRaised: [
      BoxShadow(color: Color(0x1F172B2A), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  /// Derived dark theme — a proposal until the brand confirms it.
  static const dark = MbColors(
    molGreen: _molGreen,
    marketNavy: _marketNavy,
    bhavAmber: _bhavAmber,
    surface: Color(0xFF0F1B1A),
    surfaceCard: Color(0xFF172B2A),
    surfaceGreen: Color(0xFF1C3A2E),
    surfaceGreenSoft: Color(0xFF1F3A33),
    surfaceAmber: Color(0xFF3A2A14),
    surfaceAmberSoft: Color(0xFF2E2413),
    hero: Color(0xFF1E3533),
    ink: _warmWhite,
    inkMuted: Color(0xFFA7B0AA),
    inkOnHero: _warmWhite,
    border: Color(0xFF2E4744),
    borderStrong: Color(0xFF6E827D),
    primary: Color(0xFF3DBA72),
    primaryHover: Color(0xFF52C884),
    onPrimary: Color(0xFF0F1B1A),
    primaryText: Color(0xFF3DBA72),
    accent: _bhavAmber,
    onAccent: Color(0xFF0F1B1A),
    accentText: Color(0xFFF5B26A),
    priceUp: Color(0xFFFF7A70),
    priceDown: Color(0xFF3DBA72),
    focusRing: Color(0xFF3DBA72),
    shadowCard: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
    ],
    shadowRaised: [
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  @override
  MbColors copyWith() => this;

  @override
  MbColors lerp(MbColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return MbColors(
      molGreen: c(molGreen, other.molGreen),
      marketNavy: c(marketNavy, other.marketNavy),
      bhavAmber: c(bhavAmber, other.bhavAmber),
      surface: c(surface, other.surface),
      surfaceCard: c(surfaceCard, other.surfaceCard),
      surfaceGreen: c(surfaceGreen, other.surfaceGreen),
      surfaceGreenSoft: c(surfaceGreenSoft, other.surfaceGreenSoft),
      surfaceAmber: c(surfaceAmber, other.surfaceAmber),
      surfaceAmberSoft: c(surfaceAmberSoft, other.surfaceAmberSoft),
      hero: c(hero, other.hero),
      ink: c(ink, other.ink),
      inkMuted: c(inkMuted, other.inkMuted),
      inkOnHero: c(inkOnHero, other.inkOnHero),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      primary: c(primary, other.primary),
      primaryHover: c(primaryHover, other.primaryHover),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryText: c(primaryText, other.primaryText),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentText: c(accentText, other.accentText),
      priceUp: c(priceUp, other.priceUp),
      priceDown: c(priceDown, other.priceDown),
      focusRing: c(focusRing, other.focusRing),
      shadowCard: BoxShadow.lerpList(shadowCard, other.shadowCard, t)!,
      shadowRaised: BoxShadow.lerpList(shadowRaised, other.shadowRaised, t)!,
    );
  }
}
