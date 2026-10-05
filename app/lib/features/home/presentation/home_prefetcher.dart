import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../alerts/domain/alerts.dart';

/// After Home has loaded, quietly fills the cache for the tabs people open
/// next (Alerts, My Alert Rules), so those screens open instantly. Runs at
/// most once per [cooldown]; failures are ignored — the screens fetch anyway.
@lazySingleton
class HomePrefetcher {
  HomePrefetcher(this._alerts);

  final AlertsRepository _alerts;
  DateTime? _lastRun;

  static const cooldown = Duration(minutes: 5);

  void warm() {
    final now = DateTime.now();
    if (_lastRun != null && now.difference(_lastRun!) < cooldown) return;
    _lastRun = now;
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await Future.wait([
        _alerts.watchAlerts(AlertFilter.all).drain<void>(),
        _alerts.watchAlertRules().drain<void>(),
      ]);
    } on Object {
      // Best effort only.
    }
  }
}
