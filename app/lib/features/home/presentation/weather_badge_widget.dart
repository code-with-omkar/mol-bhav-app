import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/weather/weather_service.dart';
import '../../../shared/widgets/weather_card_widget.dart';
import '../../weather/domain/weather.dart';

/// Current temperature and condition as a pill over the home header. Pops in
/// when [visible] turns on and counts the temperature up from zero.
class WeatherBadgeWidget extends StatelessWidget {
  const WeatherBadgeWidget({
    super.key,
    required this.weather,
    required this.visible,
  });

  final CurrentWeather weather;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final onHero = c.inkOnHero;
    final condition = conditionFromWmoCode(weather.weatherCode);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 350);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: AnimatedScale(
          scale: visible ? 1 : 0.8,
          alignment: Alignment.centerRight,
          curve: Curves.easeOutBack,
          duration: duration,
          child: Semantics(
            container: true,
            label:
                '${l10n.weatherTitle}, ${condition.label(l10n)}, '
                '${l10n.weatherTempDegrees(weather.temperatureC.round().toString())}',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MbSpacing.s3,
                  vertical: MbSpacing.s1 + 2,
                ),
                decoration: BoxDecoration(
                  color: onHero.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(MbRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      condition.icon,
                      size: 18,
                      color:
                          condition == WeatherCondition.clear ||
                              condition == WeatherCondition.partlyCloudy
                          ? c.bhavAmber
                          : onHero,
                    ),
                    const SizedBox(width: MbSpacing.s1 + 2),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(weather.temperatureC),
                      tween: Tween(
                        begin: reduceMotion
                            ? weather.temperatureC.toDouble()
                            : 0,
                        end: weather.temperatureC.toDouble(),
                      ),
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        l10n.weatherTempDegrees(value.round().toString()),
                        style: context.mbText.rowName.copyWith(color: onHero),
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
