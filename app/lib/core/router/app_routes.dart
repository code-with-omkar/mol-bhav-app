abstract final class AppRoutes {
  static const login = '/login';

  /// Expects an `OtpChallenge` as `extra`.
  static const verifyOtp = '/login/verify';
  static const businessProfile = '/onboarding/profile';
  static const selectCategory = '/onboarding/categories';
  static const editProfile = '$businessProfile?edit=1';
  static const editCategories = '$selectCategory?edit=1';

  // The admin app (admins only): its own tabs, separate from the user app's.
  static const admin = '/admin';
  static const adminAds = '/admin/ads';
  static const adminUsers = '/admin/users';
  static const adminApp = '/admin/app';
  static const adminAppSchedules = '/admin/app/schedules';
  static const adminHistory = '/admin/app/history';
  static const adminAppNotice = '/admin/app/notice';
  static const adminAppFeatures = '/admin/app/features';
  static const adminAppVersion = '/admin/app/version';
  static const adminAppMarkets = '/admin/app/markets';

  // Bottom-nav tabs.
  static const home = '/home';
  static const markets = '/markets';
  static const weather = '/home/weather';
  static const watchlist = '/watchlist';
  static const alerts = '/alerts';
  static const more = '/more';

  // Inside tabs (bottom nav stays visible).
  static const priceTrends = '/markets/trends';
  static const mandiPrices = '/markets/by-mandi';
  static const watchlistAdd = '/watchlist/add';
  static const reports = '/more/reports';
  static const costEstimator = '/more/estimator';
  static const adminSchedules = '/more/admin/schedules';
  static const alertRules = '/alerts/rules';
  static const helpSupport = '/more/help';
  static const raiseTicket = '/more/help/new-ticket';
  static const supportTickets = '/more/help/tickets';

  // Full screen.
  static const createAlert = '/alerts/create';
  static const opportunityPath = '/opportunities/:id';

  /// Shared deep link target, registered only when `DEEP_LINK_BASE` is set.
  static const productDeepLinkPath = '/p/:productId';
  static const billingPlans = '/billing/plans';
  static const billingCheckout = '/billing/checkout';
  static const billingSubscription = '/billing/subscription';
  static const billingSuccess = '/billing/success';
  static const notificationPreferences = '/notification-preferences';

  /// Checkout for one plan; the plan code also fixes the billing cycle.
  static String checkoutFor(String planCode) => Uri(
    path: billingCheckout,
    queryParameters: {'plan': planCode},
  ).toString();

  /// One price-feed run in the admin app.
  static String adminJob(String jobId) =>
      '$adminHistory/${Uri.encodeComponent(jobId)}';

  /// One ad campaign's daily delivery in the admin app.
  static String adminCampaign(String campaignId) =>
      '$adminAds/${Uri.encodeComponent(campaignId)}';

  /// One user in the admin app.
  static String adminUser(String userId) =>
      '$adminUsers/${Uri.encodeComponent(userId)}';

  static String opportunity(String id) =>
      '/opportunities/${Uri.encodeComponent(id)}';

  /// One support ticket's conversation.
  static String supportTicket(String ticketId) =>
      '$supportTickets/${Uri.encodeComponent(ticketId)}';

  /// Login, remembering where the user was heading so they land there after
  /// signing in (used for deep links opened while logged out).
  static String loginFrom(String from) =>
      Uri(path: login, queryParameters: {'from': from}).toString();

  /// The OTP step, carrying [from] onwards: pushing to a new location drops
  /// the query, and the session becomes valid on *this* route, so the
  /// destination has to travel with it.
  static String verifyOtpFrom(String? from) =>
      Uri(path: verifyOtp, queryParameters: {'from': ?from}).toString();

  /// Market comparison, optionally for a commodity or a category.
  /// [mandiId] badges one row — set when arriving from a shared link.
  static String marketsFor({
    String? commodityId,
    String? categoryCode,
    String? mandiId,
  }) => Uri(
    path: markets,
    queryParameters: {
      'commodityId': ?commodityId,
      'category': ?categoryCode,
      'mandi': ?mandiId,
    },
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
