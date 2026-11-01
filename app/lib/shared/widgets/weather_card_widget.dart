import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import '../../features/weather/domain/weather.dart';

extension WeatherConditionView on WeatherCondition {
  String label(AppLocalizations l10n) => switch (this) {
    WeatherCondition.clear => l10n.weatherClear,
    WeatherCondition.partlyCloudy => l10n.weatherPartlyCloudy,
    WeatherCondition.cloudy => l10n.weatherCloudy,
    WeatherCondition.rain => l10n.weatherRain,
    WeatherCondition.thunderstorm => l10n.weatherThunderstorm,
  };

  IconData get icon => switch (this) {
    WeatherCondition.clear => Icons.wb_sunny_rounded,
    WeatherCondition.partlyCloudy => Icons.wb_cloudy_rounded,
    WeatherCondition.cloudy => Icons.cloud_rounded,
    WeatherCondition.rain => Icons.water_drop_rounded,
    WeatherCondition.thunderstorm => Icons.thunderstorm_rounded,
  };

  bool get _wet =>
      this == WeatherCondition.rain || this == WeatherCondition.thunderstorm;
}

/// `Today`, `Tomorrow`, then the weekday.
String weatherDayLabel(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  final l10n = context.l10n;
  if (days == 0) return l10n.weatherToday;
  if (days == 1) return l10n.weatherTomorrow;
  return DateFormat.E(Localizations.localeOf(context).toString()).format(date);
}

/// One day's forecast over drifting cloud and falling rain sprites. [compact]
/// is the strip in the home header; the full card heads the weather tab.
/// With [expand] the full card fills the height its parent gives it.
class WeatherCardWidget extends StatelessWidget {
  const WeatherCardWidget({
    super.key,
    required this.forecast,
    required this.stationName,
    this.compact = false,
    this.expand = false,
    this.onTap,
  });

  final DailyForecast forecast;
  final String stationName;
  final bool compact;
  final bool expand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final onHero = c.inkOnHero;
    final condition = forecast.condition;
    final base = condition._wet || condition == WeatherCondition.cloudy
        ? c.marketNavy
        : c.molGreen;
    final radius = BorderRadius.circular(compact ? MbRadius.lg : MbRadius.xl);
    final tall = expand && !compact;

    final temp = Text(
      l10n.weatherTempDegrees(forecast.maxTempC.round().toString()),
      style: (compact ? t.valueMd : t.display).copyWith(
        color: onHero,
        fontSize: tall ? 56 : null,
      ),
    );
    final icon = Icon(
      condition.icon,
      size: compact
          ? 32
          : tall
          ? 72
          : 56,
      color:
          condition == WeatherCondition.clear ||
              condition == WeatherCondition.partlyCloudy
          ? c.bhavAmber
          : onHero,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(condition.label(l10n), style: t.rowName.copyWith(color: onHero)),
        Text(
          '${l10n.weatherTempRange(forecast.minTempC.round().toString(), forecast.maxTempC.round().toString())}'
          ' · ${l10n.weatherRainChance(forecast.rainChancePercent.toString())}',
          style: t.caption.copyWith(color: onHero.withValues(alpha: 0.9)),
        ),
        if (!compact) ...[
          const SizedBox(height: MbSpacing.s1),
          Text(
            l10n.weatherStation(stationName),
            style: t.caption.copyWith(color: onHero.withValues(alpha: 0.8)),
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label:
          '${l10n.weatherTitle}, ${condition.label(l10n)}, ${l10n.weatherTempDegrees(forecast.maxTempC.round().toString())}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: compact
                  ? [
                      onHero.withValues(alpha: 0.18),
                      onHero.withValues(alpha: 0.08),
                    ]
                  : [base, Color.lerp(base, Colors.black, 0.35)!],
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                height: compact
                    ? 72
                    : tall
                    ? null
                    : 168,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WeatherSprites(
                      condition: condition,
                      color: onHero,
                      compact: compact,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? MbSpacing.s3 : MbSpacing.s5,
                        vertical: compact ? MbSpacing.s2 : MbSpacing.s4,
                      ),
                      child: tall
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                icon,
                                const SizedBox(height: MbSpacing.s3),
                                temp,
                                const SizedBox(height: MbSpacing.s2),
                                details,
                              ],
                            )
                          : Row(
                              children: [
                                icon,
                                const SizedBox(width: MbSpacing.s3),
                                temp,
                                const SizedBox(width: MbSpacing.s3),
                                Expanded(child: details),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clouds drifting across and rain streaking down, behind the card content
/// (also behind the home header). The sprite group fades when the condition
/// changes.
class WeatherSprites extends StatefulWidget {
  const WeatherSprites({
    super.key,
    required this.condition,
    required this.color,
    this.compact = false,
    this.sunColor,
  });

  final WeatherCondition condition;
  final Color color;
  final bool compact;

  /// When set, clear and partly cloudy skies get a slowly pulsing sun glow in
  /// the top-right corner (the home header uses it so a clear day still
  /// moves).
  final Color? sunColor;

  @override
  State<WeatherSprites> createState() => _WeatherSpritesState();
}

class _WeatherSpritesState extends State<WeatherSprites>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  bool? _animate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate == _animate) return;
    _animate = animate;
    if (animate) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.3;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final condition = widget.condition;
    final clouds = switch (condition) {
      WeatherCondition.clear => 0,
      WeatherCondition.partlyCloudy => 2,
      _ => 4,
    };
    final drops = switch (condition) {
      WeatherCondition.rain => 14,
      WeatherCondition.thunderstorm => 22,
      _ => 0,
    };
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final w = box.maxWidth, h = box.maxHeight;
              final cloudSize = widget.compact
                  ? 44.0
                  : (h * 0.5).clamp(84.0, 140.0);
              final sun = widget.sunColor;
              final sunny =
                  condition == WeatherCondition.clear ||
                  condition == WeatherCondition.partlyCloudy;
              final glow = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 4);
              final sunSize = h * 0.9;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (sun != null && sunny)
                    Positioned(
                      right: -sunSize * 0.3,
                      top: -sunSize * 0.35,
                      width: sunSize,
                      height: sunSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              sun.withValues(alpha: 0.30 + 0.15 * glow),
                              sun.withValues(alpha: 0.08 + 0.05 * glow),
                              sun.withValues(alpha: 0),
                            ],
                            stops: const [0, 0.45, 1],
                          ),
                        ),
                      ),
                    ),
                  for (var i = 0; i < clouds; i++)
                    Positioned(
                      left: _drift(t, i / clouds, w + cloudSize) - cloudSize,
                      top: h * (0.05 + 0.2 * ((i * 37) % 5) / 4),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: 0.14 + 0.04 * (i % 3),
                        child: Icon(
                          Icons.cloud_rounded,
                          size: cloudSize * (0.8 + 0.1 * (i % 3)),
                          color: widget.color,
                        ),
                      ),
                    ),
                  for (var i = 0; i < drops; i++)
                    Positioned(
                      left: w * ((i * 53) % 100) / 100,
                      top: _fall(t, i, drops) * (h + 12) - 12,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: 0.35,
                        child: Transform.rotate(
                          angle: 0.2,
                          child: Container(
                            width: 1.6,
                            height: widget.compact ? 8 : 14,
                            decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static double _drift(double t, double phase, double span) =>
      ((t + phase) % 1) * span;

  /// Drops fall at a few different speeds, each looping on its own phase.
  static double _fall(double t, int i, int count) {
    final speed = 3 + (i % 3);
    final phase = (i * 0.618) % 1;
    return (t * speed + phase) % 1;
  }
}
