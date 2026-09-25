import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/account/presentation/account_cubits.dart';
import '../../features/account/presentation/more_page.dart';
import '../../features/account/presentation/subscription_page.dart';
import '../../features/alerts/presentation/alerts_cubits.dart';
import '../../features/alerts/presentation/alerts_page.dart';
import '../../features/alerts/presentation/create_alert_page.dart';
import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/otp_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/home/presentation/home_cubit.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/markets/presentation/buying_opportunity_page.dart';
import '../../features/markets/presentation/market_comparison_page.dart';
import '../../features/markets/presentation/markets_cubits.dart';
import '../../features/markets/presentation/price_trends_page.dart';
import '../../features/onboarding/presentation/cubit/business_profile_cubit.dart';
import '../../features/onboarding/presentation/cubit/select_category_cubit.dart';
import '../../features/onboarding/presentation/pages/business_profile_page.dart';
import '../../features/onboarding/presentation/pages/select_category_page.dart';
import '../../features/tools/presentation/cost_estimator_page.dart';
import '../../features/tools/presentation/reports_page.dart';
import '../../features/tools/presentation/tools_cubits.dart';
import '../../features/watchlist/presentation/watchlist_page.dart';
import '../session/session_manager.dart';
import '../di/injection.dart';
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
    redirect: (context, state) => _guard(session.status, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<LoginCubit>(),
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
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<BusinessProfileCubit>()..load(),
          child: const BusinessProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.selectCategory,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SelectCategoryCubit>()..load(),
          child: const SelectCategoryPage(),
        ),
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
                      ),
                    const MarketComparisonPage(),
                  );
                },
                routes: [
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
              GoRoute(
                path: AppRoutes.watchlist,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<WatchlistCubit>()..load(),
                  child: const WatchlistPage(),
                ),
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
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<ReportsCubit>()..load(),
                      child: const ReportsPage(),
                    ),
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
        path: AppRoutes.costEstimator,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<CostEstimatorCubit>()..load(),
          child: const CostEstimatorPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SubscriptionCubit>()..load(),
          child: const SubscriptionPage(),
        ),
      ),
    ],
  );
}

/// Skips Login while a session exists, keeps unfinished onboarding in the
/// onboarding flow, and returns to Login when the session ends.
String? _guard(SessionStatus status, String location) {
  final atLogin = location.startsWith(AppRoutes.login);
  final atOnboarding = location.startsWith('/onboarding');
  return switch (status) {
    SessionStatus.signedOut => atLogin ? null : AppRoutes.login,
    SessionStatus.onboarding => atOnboarding ? null : AppRoutes.businessProfile,
    SessionStatus.signedIn => atLogin ? AppRoutes.home : null,
  };
}
