import '../../../core/error/result.dart';

/// A part of the app an admin can switch off for everyone
/// (`GET /app-features`).
enum AppFeature {
  /// Every in-content ad slot (sponsored cards and AdMob native ads).
  ads('Ads'),

  /// The Reports screen and the shortcuts to it.
  reports('Reports'),

  /// The cost estimator and the shortcuts to it.
  costEstimator('CostEstimator');

  const AppFeature(this.wire);

  /// The name the API uses.
  final String wire;

  /// A feature this build does not know (added by a newer API) reads as null
  /// and is ignored.
  static AppFeature? fromWire(String value) {
    for (final f in AppFeature.values) {
      if (f.wire.toLowerCase() == value.toLowerCase()) return f;
    }
    return null;
  }
}

abstract interface class AppFeaturesRepository {
  /// Each known feature and whether it is on. One the server did not list is on.
  Future<Result<Map<AppFeature, bool>>> getAll();

  /// Admin: turns a feature on or off for everyone.
  Future<Result<void>> set(AppFeature feature, {required bool enabled});
}
