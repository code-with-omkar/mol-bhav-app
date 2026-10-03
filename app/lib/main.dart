import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/boot_splash.dart';
import 'core/di/injection.dart';
import 'core/session/session_manager.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the native splash until BootSplash has decoded the mark, so the
  // hand-off to the animated logo has no blank frame.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  // The animated logo shows while startup work runs; it swaps to the app
  // itself once [_boot] completes.
  runApp(const BootSplash(boot: _boot));
}

bool _dependenciesReady = false;

/// Safe to call again after a failure: DI is registered only once.
Future<void> _boot() async {
  await _initFirebase();
  if (!_dependenciesReady) {
    await configureDependencies();
    _dependenciesReady = true;
  }
  await getIt<SessionManager>().restore();
}

/// Push is optional: without `google-services.json` / `GoogleService-Info.plist`
/// initialisation throws, and the app must still run (sign-in, billing, prices).
/// `NotificationService` checks [Firebase.apps] before touching FCM.
Future<void> _initFirebase() async {
  if (kIsWeb || Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured; push notifications disabled: $e');
  }
}
