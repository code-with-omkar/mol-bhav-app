import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import 'weather_cubit.dart';

/// Loads the forecast when it is built and, when the device location is not
/// known yet, asks once (with a short explanation) before the system prompt.
class WeatherPermissionGate extends StatefulWidget {
  const WeatherPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<WeatherPermissionGate> createState() => _WeatherPermissionGateState();
}

class _WeatherPermissionGateState extends State<WeatherPermissionGate> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<WeatherCubit>();
    // Also covers a gate built after the cubit already asked for permission.
    cubit.fetchForecast().then((_) {
      if (mounted &&
          cubit.state.location == WeatherLocationStatus.needsPermission) {
        _ask();
      }
    });
  }

  Future<void> _ask() async {
    if (_asked) return;
    _asked = true;
    final cubit = context.read<WeatherCubit>();
    final allowed = await showWeatherPermissionDialog(context);
    if (allowed == true) await cubit.requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeatherCubit, WeatherState>(
      listenWhen: (a, b) => a.location != b.location,
      listener: (context, state) {
        if (state.location == WeatherLocationStatus.needsPermission) _ask();
      },
      child: widget.child,
    );
  }
}

Future<bool?> showWeatherPermissionDialog(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.weatherPermissionTitle),
      content: Text(l10n.weatherPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.weatherNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.weatherAllow),
        ),
      ],
    ),
  );
}
