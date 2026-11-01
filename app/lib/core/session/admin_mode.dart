import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'session_manager.dart';

/// Which app an admin is looking at. Admins start in the admin app and can
/// switch to the normal user app (and back) without signing out; non-admins
/// never see the admin app. Forgotten on sign-out, so the next login starts
/// in the admin app again.
@lazySingleton
class AdminMode extends ChangeNotifier {
  AdminMode(this._session) {
    _session.addListener(_onSession);
  }

  final SessionManager _session;
  bool _userView = false;

  /// The admin chose to see the app as a normal user.
  bool get userView => _userView;

  /// Signed in as an admin and looking at the admin app.
  bool get inAdminApp => _session.isAdmin && !_userView;

  void switchToUserView() => _set(true);

  void switchToAdminView() => _set(false);

  void _onSession() {
    if (!_session.hasSession) _set(false);
  }

  void _set(bool userView) {
    if (userView == _userView) return;
    _userView = userView;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    super.dispose();
  }
}
