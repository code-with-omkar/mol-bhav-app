import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/account/presentation/account_cubits.dart';
import '../../features/account/presentation/more_page.dart';
import '../../features/billing/presentation/cubit/coupon_cubit.dart';
import '../../features/billing/presentation/cubit/plans_cubit.dart';
import '../../features/billing/presentation/cubit/subscription_cubit.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/payment_success_page.dart';
import '../../features/billing/presentation/pages/plans_page.dart';
import '../../features/billing/presentation/pages/subscription_page.dart';
import '../../features/alerts/presentation/alert_rules_cubit.dart';
import '../../features/alerts/presentation/alert_rules_page.dart';
import '../../features/alerts/presentation/alerts_cubits.dart';
import '../../features/alerts/presentation/alerts_page.dart';
import '../../features/alerts/presentation/create_alert_page.dart';
import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/password_auth.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/login_methods_cubit.dart';
import '../../features/auth/presentation/cubit/otp_cubit.dart';
import '../../features/auth/presentation/cubit/password_login_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/home/presentation/home_cubit.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/markets/presentation/buying_opportunity_page.dart';
import '../../features/markets/presentation/mandi_prices_cubit.dart';
import '../../features/markets/presentation/mandi_prices_page.dart';
import '../../features/markets/presentation/market_comparison_page.dart';
import '../../features/markets/presentation/markets_cubits.dart';
import '../../features/markets/presentation/price_trends_page.dart';
import '../../features/onboarding/presentation/cubit/business_profile_cubit.dart';
import '../../features/onboarding/presentation/cubit/select_category_cubit.dart';
import '../../features/onboarding/presentation/pages/business_profile_page.dart';
import '../../features/onboarding/presentation/pages/select_category_page.dart';
import '../../features/notifications/presentation/notification_preferences_page.dart';
import '../../features/notifications/presentation/notification_prefs_cubit.dart';
import '../../features/support/presentation/help_support_page.dart';
import '../../features/support/presentation/my_tickets_page.dart';
import '../../features/support/presentation/raise_ticket_page.dart';
import '../../features/support/presentation/support_cubits.dart';
import '../../features/support/presentation/ticket_thread_page.dart';
import '../../features/tools/presentation/cost_estimator_page.dart';
import '../../features/tools/presentation/reports_page.dart';
import '../../features/tools/presentation/tools_cubits.dart';
import '../../features/watchlist/presentation/watchlist_page.dart';
import '../../features/watchlist/presentation/watchlist_picker.dart';
import '../session/session_manager.dart';
import '../di/injection.dart';
import '../share/deep_link_config.dart';
import 'app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Provides a fresh cubit per distinct URL, so a new query (another
/// commodity, another market) rebuilds the screen's state.
Widget _screen<C extends StateStreamableSource<Object?>>(
  GoRouterState state,
  C Function() create,
  Widget child,
) => BlocProvider<C>(
  key: ValueKey(state.uri.toString()),
  create: (_) => create(),
  child: child,
);

GoRouter createAppRouter(SessionManager session) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) => _guard(session.status, state),
    routes: [
      // Shared deep link: {DEEP_LINK_BASE}/p/{productId}?mandi={mandiId}.
      // Registered only when a base is configured — an app with no verified
      // domain must not claim to handle the path. It is a pure redirect, so
      // the guard above sends a logged-out visitor to Login first and brings
      // them back here afterwards.
      if (DeepLinkConfig.isEnabled)
        GoRoute(
          path: AppRoutes.productDeepLinkPath,
          redirect: (context, state) => AppRoutes.marketsFor(
            commodityId: state.pathParameters['productId'],
            mandiId: state.uri.queryParameters['mandi'],
          ),
        ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<LoginCubit>()),
            // Built by hand (like SubscriptionTierSync) so no injectable
            // codegen run is needed; the repository is already registered.
            BlocProvider(
              create: (_) =>
                  LoginMethodsCubit(GetLoginMethods(getIt<AuthRepository>()))
                    ..load(),
            ),
            BlocProvider(
              create: (_) => PasswordLoginCubit(
                LoginWithPassword(getIt<AuthRepository>()),
                RegisterWithPassword(getIt<AuthRepository>()),
              ),
            ),
          ],
          child: LoginPage(sessionExpired: session.consumeExpiredNotice()),
        ),
        routes: [
          GoRoute(
            path: 'verify',
            redirect: (context, state) =>
                state.extra is OtpChallenge ? null : AppRoutes.login,
            builder: (context, state) => BlocProvider(
              create: (_) =>
                  getIt<OtpCubit>(param1: state.extra! as OtpChallenge),
              child: const OtpPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.businessProfile,
        builder: (context, state) {
          final editing = state.uri.queryParameters['edit'] == '1';
          return BlocProvider(
            create: (_) =>
                getIt<BusinessProfileCubit>()..load(prefill: editing),
            child: BusinessProfilePage(editing: editing),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.selectCategory,
        builder: (context, state) {
          final editing = state.uri.queryParameters['edit'] == '1';
          return BlocProvider(
            create: (_) => getIt<SelectCategoryCubit>()..load(prefill: editing),
            child: SelectCategoryPage(editing: editing),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<HomeCubit>()..load(),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.markets,
                builder: (context, state) {
                  final q = state.uri.queryParameters;
                  return _screen(
                    state,
                    () => getIt<MarketComparisonCubit>()
                      ..load(
                        commodityId: q['commodityId'],
                        categoryCode: q['category'],
                        highlightMarketId: q['mandi'],
                      ),
                    const MarketComparisonPage(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'by-mandi',
                    builder: (context, state) => _screen(
                      state,
                      () => getIt<MandiPricesCubit>()..load(),
                      const MandiPricesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'trends',
                    redirect: (context, state) {
                      final q = state.uri.queryParameters;
                      return q['commodityId'] == null || q['marketId'] == null
                          ? AppRoutes.markets
                          : null;
                    },
                    builder: (context, state) {
                      final q = state.uri.queryParameters;
                      final commodityId = q['commodityId']!;
                      final marketId = q['marketId']!;
                      return _screen(
                        state,
                        () =>
                            getIt<PriceTrendsCubit>()
                              ..load(commodityId, marketId),
                        PriceTrendsPage(
                          commodityId: commodityId,
                          marketId: marketId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // WatchlistCubit is app-wide (see MolBhavApp).
              GoRoute(
                path: AppRoutes.watchlist,
                builder: (context, state) => const WatchlistPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<WatchlistPickerCubit>()..load(),
                      child: const WatchlistPickerPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.alerts,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AlertsCubit>()..load(),
                  child: const AlertsPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) {
                      final q = state.uri.queryParameters;
                      return _screen(
                        state,
                        () => getIt<CreateAlertCubit>()
                          ..load(
                            commodityId: q['commodityId'],
                            marketId: q['marketId'],
                          ),
                        const CreateAlertPage(),
                      );
                    },
                  ),
                  // Inside the Alerts tab so the bottom nav stays visible.
                  GoRoute(
                    path: 'rules',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AlertRulesCubit>()..load(),
                      child: const AlertRulesPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<MoreCubit>()..load(),
                  child: const MorePage(),
                ),
                routes: [
                  // Inside the More tab so the bottom nav stays visible.
                  GoRoute(
                    path: 'estimator',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<CostEstimatorCubit>()..load(),
                      child: const CostEstimatorPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<ReportsCubit>()..load(),
                      child: const ReportsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<HelpSupportCubit>()..load(),
                      child: const HelpSupportPage(),
                    ),
                    routes: [
                      // Declared before 'tickets' only for readability; the
                      // paths cannot collide.
                      GoRoute(
                        path: 'new-ticket',
                        builder: (context, state) => BlocProvider(
                          create: (_) => getIt<RaiseTicketCubit>(),
                          child: const RaiseTicketPage(),
                        ),
                      ),
                      GoRoute(
                        path: 'tickets',
                        builder: (context, state) => BlocProvider(
                          create: (_) => getIt<MyTicketsCubit>()..load(),
                          child: const MyTicketsPage(),
                        ),
                        routes: [
                          GoRoute(
                            path: ':ticketId',
                            builder: (context, state) => _screen(
                              state,
                              () =>
                                  getIt<TicketThreadCubit>()
                                    ..load(state.pathParameters['ticketId']!),
                              const TicketThreadPage(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.opportunityPath,
        builder: (context, state) => _screen(
          state,
          () =>
              getIt<BuyingOpportunityCubit>()
                ..load(state.pathParameters['id']!),
          const BuyingOpportunityPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationPreferences,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<NotificationPrefsCubit>()..load(),
          child: const NotificationPreferencesPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billingPlans,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<PlansCubit>()..load(),
          child: const PlansPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billingCheckout,
        redirect: (context, state) => state.uri.queryParameters['plan'] == null
            ? AppRoutes.billingPlans
            : null,
        builder: (context, state) {
          final planCode = state.uri.queryParameters['plan']!;
          return MultiBlocProvider(
            key: ValueKey(planCode),
            providers: [
              BlocProvider(create: (_) => getIt<PlansCubit>()..load()),
              BlocProvider(create: (_) => getIt<CouponCubit>()),
              BlocProvider(create: (_) => getIt<SubscriptionCubit>()),
            ],
            child: CheckoutPage(planCode: planCode),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.billingSubscription,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SubscriptionCubit>()..load(),
          child: const SubscriptionPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.billingSuccess,
        builder: (context, state) => const PaymentSuccessPage(),
      ),
    ],
  );
}

/// Skips Login while a session exists, keeps unfinished onboarding in the
/// onboarding flow, and returns to Login when the session ends.
///
/// A logged-out visitor who followed a deep link is sent to Login carrying
/// `?from=<the link>`, and lands on it once signed in instead of on Home — so
/// a shared price opens the price, not the front door.
String? _guard(SessionStatus status, GoRouterState state) {
  final location = state.matchedLocation;
  final atLogin = location.startsWith(AppRoutes.login);
  final atOnboarding = location.startsWith('/onboarding');
  return switch (status) {
    SessionStatus.signedOut when atLogin => null,
    SessionStatus.signedOut => AppRoutes.loginFrom(state.uri.toString()),
    SessionStatus.onboarding => atOnboarding ? null : AppRoutes.businessProfile,
    SessionStatus.signedIn when atLogin =>
      _continueTo(state.uri.queryParameters['from']) ?? AppRoutes.home,
    SessionStatus.signedIn => null,
  };
}

/// A `from` value is only honoured when it is a path inside this app: an
/// absolute or scheme-carrying value could send a freshly signed-in user
/// anywhere.
String? _continueTo(String? from) {
  if (from == null || from.isEmpty || !from.startsWith('/')) return null;
  if (from.startsWith('//') || from.startsWith(AppRoutes.login)) return null;
  return from;
}
