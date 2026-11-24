import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_permission_handler.dart';

/// The one-time "allow notifications and location" step shown on the first
/// launch after install, before Login. The router listens to it, so finishing
/// (allowing or skipping) moves the user on.
///
/// Skipping is fine: the app asks again where a feature needs the permission
/// (the Weather page asks for location, turning push on asks for notifications).
@lazySingleton
class FirstRunPermissions extends ChangeNotifier {
  FirstRunPermissions(this._prefs, this._location);

  static const _doneKey = 'permissions.first_run_done';

  final SharedPreferences _prefs;
  final LocationPermissionHandler _location;

  /// Not asked yet. Always false on the web, which has no install step.
  bool get pending => !kIsWeb && !(_prefs.getBool(_doneKey) ?? false);

  /// Shows the system prompts one after the other, then moves on whatever the
  /// answers were. Location is also resolved, so Weather is ready at once.
  Future<void> allow() async {
    try {
      await Permission.notification.request();
    } on Object {
      // A denied or unsupported prompt never blocks the first launch.
    }
    await _location.resolve();
    await finish();
  }

  /// Marks the step as done without asking for anything.
  Future<void> finish() async {
    await _prefs.setBool(_doneKey, true);
    notifyListeners();
  }
}
