import 'package:shared_preferences/shared_preferences.dart';

/// Backend configuration. The default is set at build time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.14:5189/api/v1`.
///
/// Debug builds can also point at another server without rebuilding (Login →
/// Server): a phone on a different Wi-Fi than the PC that runs the API only
/// needs the PC's new address. The choice is kept on the device.
abstract final class ApiConfig {
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5189/api/v1',
  );

  static const _prefsKey = 'api.baseUrl.override';

  static String? _override;

  /// The server the app talks to: the saved choice, else the build default.
  static String get baseUrl => _override ?? defaultBaseUrl;

  /// Whether a saved choice replaces the build default.
  static bool get isOverridden => _override != null;

  /// Reads the saved choice at startup, before any HTTP client is created.
  static void restore(SharedPreferences prefs) {
    _override = prefs.getString(_prefsKey);
  }

  /// Saves [baseUrl] (already normalised); `null` goes back to the default.
  static Future<void> save(SharedPreferences prefs, String? baseUrl) async {
    _override = baseUrl;
    if (baseUrl == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, baseUrl);
    }
  }

  /// Generous timeouts: users are often on slow rural connections.
  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);
}

/// Turns what a person types into an API base URL, or `null` when it cannot be
/// one: `192.168.1.14:5189` → `http://192.168.1.14:5189/api/v1`. A full URL
/// that already ends in a path is kept as typed.
String? normalizeServerAddress(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return null;
  }
  var path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return uri.replace(path: path.isEmpty ? '/api/v1' : path).toString();
}
