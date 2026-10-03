import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

import '../network/api_call.dart';
import '../../features/notifications/data/notification_prefs_data.dart';

import 'package:flutter/foundation.dart';

/// Manages FCM device token registration + foreground message handling.
///
/// Call [initialize] once after sign-in and [dispose] before sign-out.
@lazySingleton
class NotificationService {
  NotificationService(this._deviceDataSource);

  final NotificationDeviceDataSource _deviceDataSource;

  String? _currentToken;

  /// False on web and whenever Firebase was not configured at startup.
  bool get _firebaseReady => !kIsWeb && Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_firebaseReady) return;
    final messaging = FirebaseMessaging.instance;

    // Request permission (required on iOS and web; Android grants by default).
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token == null) return;

    _currentToken = token;
    await _registerToken(token);

    // Re-register when FCM rotates the token.
    messaging.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await _registerToken(newToken);
    });
  }

  /// Called on logout — removes the token from the server and invalidates it in FCM.
  Future<void> dispose() async {
    final token = _currentToken;
    if (token != null) {
      await runApiCall(() => _deviceDataSource.unregisterToken(token));
    }
    _currentToken = null;
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      // Never block sign-out on FCM.
      debugPrint('FCM deleteToken failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = currentDevicePlatform();
    await runApiCall(() => _deviceDataSource.registerToken(token, platform));
  }
}
