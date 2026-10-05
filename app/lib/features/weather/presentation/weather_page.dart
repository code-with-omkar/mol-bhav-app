import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/weather_card_widget.dart';
import '../domain/weather.dart';
import 'weather_cubit.dart';
import 'weather_permission_gate.dart';

/// Today and the next six days; tap a day to see its detail.
class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WeatherPermissionGate(
      child: Scaffold(
        appBar: MbAppBar(title: context.l10n.weatherTitle),
        body: BlocBuilder<WeatherCubit, WeatherState>(
          builder: (context, state) {
            final forecast = state.forecast.data;
            if (forecast != null && forecast.days.isNotEmpty) {
              return MbRevalidating(
                active: state.forecast.isRevalidating,
                child: RefreshIndicator(
                  onRefresh: context.read<WeatherCubit>().refreshWeather,
                  child: _Forecast(
                    forecast: forecast,
                    selected: state.selectedDay,
                  ),
                ),
              );
            }
            if (state.location == WeatherLocationStatus.resolved) {
              final failure = state.forecast.failure;
              return state.forecast.status == LoadStatus.failure &&
                      failure != null
                  ? MbErrorView(
                      failure: failure,
                      onRetry: context.read<WeatherCubit>().refreshWeather,
                    )
                  : const MbLoadingView();
            }
            return _NoForecast(state: state);
          },
        ),
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.forecast, required this.selected});

  final SevenDayForecast forecast;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final day = forecast.days[selected];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: MbSpacing.screenPadding,
      children: [
        WeatherCardWidget(forecast: day, stationName: forecast.stationName),
        const SizedBox(height: MbSpacing.s4),
        Row(
          children: [
            _Stat(
              label: l10n.weatherHumidity,
              value: '${day.humidityPercent}%',
            ),
            const SizedBox(width: MbSpacing.s3),
            _Stat(
              label: l10n.weatherWind,
              value: l10n.weatherWindValue(day.windKmph.round().toString()),
            ),
            const SizedBox(width: MbSpacing.s3),
            _Stat(label: l10n.weatherRain, value: '${day.rainChancePercent}%'),
          ],
        ),
        const SizedBox(height: MbSpacing.s6),
        MbSectionHeader(title: l10n.weatherSevenDay),
        const SizedBox(height: MbSpacing.s3),
        Semantics(
          label: l10n.weatherSelectDay,
          child: SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: MbSpacing.s2),
              itemBuilder: (context, i) => _DayChip(
                day: forecast.days[i],
                selected: i == selected,
                onTap: () => context.read<WeatherCubit>().selectDay(i),
              ),
            ),
          ),
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(
          l10n.weatherUpdated(
            TimeOfDay.fromDateTime(forecast.issuedAt).format(context),
          ),
          style: context.mbText.caption.copyWith(color: c.inkMuted),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(MbSpacing.s3),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(MbRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: MbSpacing.s1),
            Text(value, style: t.rowName.copyWith(color: c.ink)),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DailyForecast day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final fg = selected ? c.onPrimary : c.ink;
    final label = weatherDayLabel(context, day.date);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${day.condition.label(l10n)}',
      child: Material(
        color: selected ? c.primary : c.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MbRadius.md),
          side: BorderSide(color: selected ? c.primary : c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(MbRadius.md),
          onTap: onTap,
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: t.caption.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: MbSpacing.s2),
                Icon(day.condition.icon, size: 24, color: fg),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.weatherTempDegrees(day.maxTempC.round().toString()),
                  style: t.rowName.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoForecast extends StatelessWidget {
  const _NoForecast({required this.state});

  final WeatherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<WeatherCubit>();
    final location = state.location;
    if (location == WeatherLocationStatus.unknown ||
        location == WeatherLocationStatus.resolving) {
      return const MbLoadingView();
    }
    final message = switch (location) {
      WeatherLocationStatus.serviceOff => l10n.weatherServiceOff,
      WeatherLocationStatus.deniedForever => l10n.weatherDeniedForever,
      WeatherLocationStatus.outOfCoverage => l10n.weatherOutOfCoverage,
      WeatherLocationStatus.unavailable => l10n.weatherUnavailable,
      _ => l10n.weatherNoForecastBody,
    };
    final needsSettings =
        location == WeatherLocationStatus.serviceOff ||
        location == WeatherLocationStatus.deniedForever;
    return Center(
      child: Padding(
        padding: MbSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: context.mbColors.inkMuted,
            ),
            const SizedBox(height: MbSpacing.s3),
            Text(l10n.weatherNoForecast, style: context.mbText.title),
            const SizedBox(height: MbSpacing.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.mbText.body,
            ),
            if (location != WeatherLocationStatus.outOfCoverage) ...[
              const SizedBox(height: MbSpacing.s4),
              FilledButton(
                onPressed: needsSettings
                    ? cubit.openSettings
                    : cubit.requestLocation,
                child: Text(
                  needsSettings
                      ? l10n.weatherOpenSettings
                      : l10n.weatherEnableLocation,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
