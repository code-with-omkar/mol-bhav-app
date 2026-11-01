import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/settings/home_weather_animation_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/weather_card_widget.dart';
import '../../weather/domain/weather.dart';
import '../../weather/presentation/weather_cubit.dart';
import '../../weather/presentation/weather_permission_gate.dart';

/// Home header with weather: a weather button on the greeting line (always
/// shown) and, once today's forecast is known, the weather screen's cloud and
/// rain animation across the whole header — unless the user turned it off.
///
/// Tapping the button without location asks for it right here and stays on
/// Home; with a forecast (or when only settings can help) it opens the
/// weather screen.
class HomeWeatherHero extends StatefulWidget {
  const HomeWeatherHero({
    super.key,
    required this.header,
    required this.onOpenWeather,
  });

  /// The header, given the background to draw behind its content.
  final Widget Function(Widget? background) header;
  final VoidCallback onOpenWeather;

  @override
  State<HomeWeatherHero> createState() => _HomeWeatherHeroState();
}

class _HomeWeatherHeroState extends State<HomeWeatherHero> {
  @override
  void initState() {
    super.initState();
    // A remembered station loads the forecast; otherwise this only records
    // that permission is needed — Home never prompts on its own.
    context.read<WeatherCubit>().fetchForecast();
  }

  Future<void> _onTap(WeatherState state) async {
    final cubit = context.read<WeatherCubit>();
    switch (state.location) {
      case WeatherLocationStatus.unknown:
      case WeatherLocationStatus.needsPermission:
      case WeatherLocationStatus.denied:
        final allowed = await showWeatherPermissionDialog(context);
        if (allowed == true) await cubit.requestLocation();
      case WeatherLocationStatus.resolving:
        return;
      case WeatherLocationStatus.resolved:
      case WeatherLocationStatus.deniedForever:
      case WeatherLocationStatus.serviceOff:
      case WeatherLocationStatus.outOfCoverage:
      case WeatherLocationStatus.unavailable:
        // Forecast, or the screen that explains and links to settings.
        widget.onOpenWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Header rows above the greeting: safe area, padding, the 48px top row
    // and the gap below it.
    final top =
        MediaQuery.paddingOf(context).top + MbSpacing.s2 + 48 + MbSpacing.s5;
    final onHero = context.mbColors.inkOnHero;
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        final today = state.today;
        return Stack(
          children: [
            widget.header(
              // The moving scene is optional (More → Home weather animation)
              // and also off when the system asks for reduced motion.
              BlocBuilder<HomeWeatherAnimationCubit, bool>(
                bloc: getIt<HomeWeatherAnimationCubit>(),
                builder: (context, animate) {
                  final scene =
                      animate && !MediaQuery.disableAnimationsOf(context)
                      ? today
                      : null;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: scene == null
                        ? const SizedBox.shrink()
                        : WeatherSprites(
                            key: ValueKey(scene.condition),
                            condition: scene.condition,
                            color: onHero,
                            sunColor: context.mbColors.bhavAmber,
                          ),
                  );
                },
              ),
            ),
            Positioned(
              top: top,
              right: MbSpacing.s4,
              child: _WeatherButton(
                today: today,
                // Only while location or the forecast is actually being
                // fetched; before permission the forecast is still `initial`.
                loading:
                    state.location == WeatherLocationStatus.resolving ||
                    (today == null &&
                        state.location == WeatherLocationStatus.resolved &&
                        state.forecast.status == LoadStatus.loading),
                onTap: () => _onTap(state),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Weather icon in a pill; with a forecast it also shows today's high.
class _WeatherButton extends StatelessWidget {
  const _WeatherButton({
    required this.today,
    required this.loading,
    required this.onTap,
  });

  final DailyForecast? today;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final onHero = c.inkOnHero;
    final day = today;
    final condition = day?.condition;
    final sunny =
        condition == WeatherCondition.clear ||
        condition == WeatherCondition.partlyCloudy;
    final temp = day == null
        ? null
        : l10n.weatherTempDegrees(day.maxTempC.round().toString());

    return Semantics(
      button: true,
      label: day == null
          ? '${l10n.weatherTitle}, ${loading ? l10n.weatherHomeLoading : l10n.weatherHomePrompt}'
          : '${l10n.weatherTitle}, ${condition!.label(l10n)}, $temp',
      child: ExcludeSemantics(
        child: Material(
          color: onHero.withValues(alpha: 0.18),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: day == null ? MbSpacing.s2 : MbSpacing.s3,
                  vertical: MbSpacing.s2,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading)
                        SizedBox.square(
                          dimension: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onHero,
                            ),
                          ),
                        )
                      else
                        Icon(
                          condition?.icon ?? Icons.wb_cloudy_rounded,
                          size: 22,
                          color: sunny || day == null ? c.bhavAmber : onHero,
                        ),
                      if (temp != null) ...[
                        const SizedBox(width: MbSpacing.s1 + 2),
                        Text(
                          temp,
                          style: context.mbText.rowName.copyWith(color: onHero),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
