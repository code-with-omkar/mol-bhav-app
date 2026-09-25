abstract final class AppRoutes {
  static const login = '/login';

  /// Expects an `OtpChallenge` as `extra`.
  static const verifyOtp = '/login/verify';
  static const businessProfile = '/onboarding/profile';
  static const selectCategory = '/onboarding/categories';

  // Bottom-nav tabs.
  static const home = '/home';
  static const markets = '/markets';
  static const watchlist = '/watchlist';
  static const alerts = '/alerts';
  static const more = '/more';

  // Inside tabs (bottom nav stays visible).
  static const priceTrends = '/markets/trends';
  static const reports = '/more/reports';

  // Full screen.
  static const createAlert = '/alerts/create';
  static const opportunityPath = '/opportunities/:id';
  static const costEstimator = '/estimator';
  static const subscription = '/subscription';

  static String opportunity(String id) =>
      '/opportunities/${Uri.encodeComponent(id)}';

  /// Market comparison, optionally for a commodity or a category.
  static String marketsFor({String? commodityId, String? categoryCode}) => Uri(
    path: markets,
    queryParameters: {'commodityId': ?commodityId, 'category': ?categoryCode},
  ).toString();

  static String trendsFor(String commodityId, String marketId) => Uri(
    path: priceTrends,
    queryParameters: {'commodityId': commodityId, 'marketId': marketId},
  ).toString();

  static String createAlertFor({String? commodityId, String? marketId}) => Uri(
    path: createAlert,
    queryParameters: {'commodityId': ?commodityId, 'marketId': ?marketId},
  ).toString();
}
