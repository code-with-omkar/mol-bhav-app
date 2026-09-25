/// Backend configuration, supplied at build time:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  /// Generous timeouts: users are often on slow rural connections.
  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);
}
