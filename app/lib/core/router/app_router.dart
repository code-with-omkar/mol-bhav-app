import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/account/presentation/account_cubits.dart';
import '../../features/account/presentation/more_page.dart';
import '../../features/admin/domain/admin_ingestion.dart';
import '../../features/admin/presentation/admin_ads_cubit.dart';
import '../../features/admin/domain/admin_ads.dart';
import '../../features/admin/domain/admin_campaigns.dart';
import '../../features/admin/presentation/admin_campaign_form_cubit.dart';
import '../../features/admin/presentation/admin_campaign_form_page.dart';
import '../../features/admin/presentation/admin_campaign_list_cubit.dart';
import '../../features/admin/presentation/admin_campaign_list_page.dart';
import '../../features/admin/presentation/admin_ads_page.dart';
import '../../features/admin/presentation/admin_features_cubit.dart';
import '../../features/admin/presentation/admin_audit_cubit.dart';
import '../../features/admin/presentation/admin_coupons_cubit.dart';
import '../../features/admin/presentation/admin_coupons_page.dart';
import '../../features/admin/presentation/admin_subscriptions_cubit.dart';
import '../../features/admin/presentation/admin_subscriptions_page.dart';
import '../../features/admin/presentation/admin_plans_cubit.dart';
import '../../features/admin/presentation/admin_plans_page.dart';
import '../../features/admin/presentation/admin_ticket_thread_cubit.dart';
import '../../features/admin/presentation/admin_ticket_thread_page.dart';
import '../../features/admin/presentation/admin_tickets_cubit.dart';
import '../../features/admin/presentation/admin_tickets_page.dart';
import '../../features/admin/presentation/admin_audit_page.dart';
import '../../features/admin/presentation/admin_categories_cubit.dart';
import '../../features/admin/presentation/admin_categories_page.dart';
import '../../features/admin/presentation/admin_commodities_cubit.dart';
import '../../features/admin/presentation/admin_commodities_page.dart';
import '../../features/admin/presentation/admin_mandis_cubit.dart';
import '../../features/admin/presentation/admin_mandis_page.dart';
import '../../features/admin/presentation/admin_markets_cubit.dart';
import '../../features/admin/presentation/admin_suppliers_cubit.dart';
import '../../features/admin/presentation/admin_suppliers_page.dart';
import '../../features/admin/presentation/admin_states_cubit.dart';
import '../../features/admin/presentation/admin_states_page.dart';
import '../../features/admin/presentation/admin_units_cubit.dart';
import '../../features/admin/presentation/admin_units_page.dart';
import '../../features/admin/presentation/admin_products_cubit.dart';
import '../../features/admin/presentation/admin_products_page.dart';
import '../../features/admin/presentation/admin_markets_page.dart';
import '../../features/admin/presentation/admin_version_cubit.dart';
import '../../features/admin/presentation/admin_version_page.dart';
import '../../features/admin/presentation/admin_features_page.dart';
import '../../features/admin/presentation/admin_notice_cubit.dart';
import '../../features/admin/presentation/admin_notice_page.dart';
import '../../features/admin/presentation/admin_campaign_cubit.dart';
import '../../features/admin/presentation/admin_campaign_page.dart';
import '../../features/admin/presentation/admin_app_page.dart';
import '../../features/admin/presentation/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/admin_schedules_cubit.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/pull_history_cubit.dart';
import '../../features/admin/presentation/pull_history_page.dart';
import '../../features/admin/presentation/pull_job_cubit.dart';
import '../../features/admin/presentation/pull_job_page.dart';
import '../../features/admin/presentation/admin_user_detail_cubit.dart';
import '../../features/admin/presentation/admin_user_detail_page.dart';
import '../../features/admin/presentation/admin_users_cubit.dart';
import '../../features/admin/presentation/admin_users_page.dart';
import '../../features/admin/presentation/admin_schedules_page.dart';
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
import '../../features/auth/presentation/cubit/google_login_cubit.dart';
import '../../features/auth/presentation/cubit/login_methods_cubit.dart';
import '../../features/auth/presentation/cubit/otp_cubit.dart';
import '../../features/auth/presentation/cubit/password_login_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/home/presentation/home_cubit.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/weather/presentation/weather_page.dart';
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
import '../../features/onboarding/presentation/permissions_page.dart';
import '../../features/account/presentation/change_password_cubit.dart';
import '../../features/account/presentation/change_password_page.dart';
import '../../features/suppliers/presentation/suppliers_cubit.dart';
import '../../features/suppliers/presentation/suppliers_page.dart';
import '../../features/tools/presentation/cost_estimator_page.dart';
import '../../features/tools/presentation/reports_page.dart';
import '../../features/tools/presentation/tools_cubits.dart';
import '../../features/watchlist/presentation/watchlist_page.dart';
import '../../features/watchlist/presentation/watchlist_picker.dart';
import '../permissions/first_run_permissions.dart';
import '../session/admin_mode.dart';
import '../session/session_manager.dart';
import '../storage/saved_credentials_store.dart';
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

GoRouter createAppRouter(
  SessionManager session,
  AdminMode adminMode,
  FirstRunPermissions firstRun,
) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    // Switching between the admin and user apps re-runs the guard too, and so
    // does finishing the first-launch permissions step.
    refreshListenable: Listenable.merge([session, adminMode, firstRun]),
    redirect: (context, state) => _guard(session, adminMode, firstRun, state),
    routes: [
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsPage(),
      ),
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
                savedCredentials: getIt<SavedCredentialsStore>(),
              )..loadSaved(),
            ),
            BlocProvider(
              create: (_) =>
                  GoogleLoginCubit(LoginWithGoogle(getIt<AuthRepository>())),
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
                routes: [
                  GoRoute(
                    path: 'weather',
                    builder: (context, state) => const WeatherPage(),
                  ),
                ],
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
                    path: 'password',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<ChangePasswordCubit>(),
                      child: const ChangePasswordPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'suppliers',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<SuppliersCubit>()..load(),
                      child: const SuppliersPage(),
                    ),
                  ),
                  // Admin only: the More entry is hidden for other roles and
                  // every admin endpoint returns 403 to them anyway.
                  GoRoute(
                    path: 'admin/schedules',
                    builder: (context, state) => BlocProvider(
                      create: (_) =>
                          AdminSchedulesCubit(getIt<AdminIngestionRepository>())
                            ..load(),
                      child: const AdminSchedulesPage(),
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
      // The admin app. The guard keeps everyone but admins out of it, and the
      // API refuses admin calls from anyone else regardless.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.admin,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AdminDashboardCubit>()..load(),
                  child: const AdminDashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminAds,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AdminAdsCubit>()..load(),
                  child: const AdminAdsPage(),
                ),
                routes: [
                  // Before ':id', which would otherwise read "campaigns" as an id.
                  GoRoute(
                    path: 'campaigns',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminCampaignListCubit>()..load(),
                      child: const AdminCampaignListPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => BlocProvider(
                          create: (_) =>
                              getIt<AdminCampaignFormCubit>()..load(),
                          child: const AdminCampaignFormPage(),
                        ),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        // The list passes the campaign; a bare link has none.
                        redirect: (context, state) =>
                            state.extra is AdminCampaign
                            ? null
                            : AppRoutes.adminCampaigns,
                        builder: (context, state) {
                          final campaign = state.extra! as AdminCampaign;
                          return BlocProvider(
                            create: (_) =>
                                getIt<AdminCampaignFormCubit>()
                                  ..load(campaign: campaign),
                            child: AdminCampaignFormPage(campaign: campaign),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BlocProvider(
                        create: (_) => getIt<AdminCampaignCubit>()..load(id),
                        child: AdminCampaignPage(
                          campaignId: id,
                          campaign: state.extra as CampaignPerformance?,
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
                path: AppRoutes.adminUsers,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AdminUsersCubit>()..load(),
                  child: const AdminUsersPage(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BlocProvider(
                        create: (_) => getIt<AdminUserDetailCubit>()..load(id),
                        child: AdminUserDetailPage(userId: id),
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
                path: AppRoutes.adminApp,
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<AdminDashboardCubit>()..load(),
                  child: const AdminAppPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'plans',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminPlansCubit>()..load(),
                      child: const AdminPlansPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'subscriptions',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminSubscriptionsCubit>()..load(),
                      child: const AdminSubscriptionsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'coupons',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminCouponsCubit>()..load(),
                      child: const AdminCouponsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminTicketsCubit>()..load(),
                      child: const AdminTicketsPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            create: (_) =>
                                getIt<AdminTicketThreadCubit>()..load(id),
                            child: AdminTicketThreadPage(ticketId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'activity',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminAuditCubit>()..load(),
                      child: const AdminAuditPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'markets',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminMarketsCubit>()..load(),
                      child: const AdminMarketsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'suppliers',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminSuppliersCubit>()..load(),
                      child: const AdminSuppliersPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'states',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminStatesCubit>()..load(),
                      child: const AdminStatesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'mandis',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminMandisCubit>()..load(),
                      child: const AdminMandisPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'units',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminUnitsCubit>()..load(),
                      child: const AdminUnitsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminCategoriesCubit>()..load(),
                      child: const AdminCategoriesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'products',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminProductsCubit>()..load(),
                      child: const AdminProductsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'commodities',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminCommoditiesCubit>()..load(),
                      child: const AdminCommoditiesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'version',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminVersionCubit>()..load(),
                      child: const AdminVersionPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'features',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminFeaturesCubit>()..load(),
                      child: const AdminFeaturesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'notice',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<AdminNoticeCubit>()..load(),
                      child: const AdminNoticePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<PullHistoryCubit>()..load(),
                      child: const PullHistoryPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider(
                            create: (_) => getIt<PullJobCubit>()..load(id),
                            child: PullJobPage(jobId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'schedules',
                    builder: (context, state) => BlocProvider(
                      create: (_) =>
                          AdminSchedulesCubit(getIt<AdminIngestionRepository>())
                            ..load(),
                      child: const AdminSchedulesPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
///
/// Admins land in the admin app instead of the user's Home, and stay there
/// until they choose "View as user"; anyone else is kept out of `/admin`.
String? _guard(
  SessionManager session,
  AdminMode adminMode,
  FirstRunPermissions firstRun,
  GoRouterState state,
) {
  final location = state.matchedLocation;
  final atPermissions = location == AppRoutes.permissions;
  // A fresh install (no session yet) is asked for permissions once, before
  // Login. Someone already signed in never sees the step.
  if (firstRun.pending && session.status == SessionStatus.signedOut) {
    return atPermissions ? null : AppRoutes.permissions;
  }
  if (atPermissions) return AppRoutes.login;
  final atLogin = location.startsWith(AppRoutes.login);
  final atOnboarding = location.startsWith('/onboarding');
  final atAdmin =
      location == AppRoutes.admin || location.startsWith('${AppRoutes.admin}/');
  // A shared price link still opens the price, even for an admin.
  final atDeepLink = location.startsWith('/p/');
  return switch (session.status) {
    SessionStatus.signedOut when atLogin => null,
    SessionStatus.signedOut => AppRoutes.loginFrom(state.uri.toString()),
    SessionStatus.onboarding => atOnboarding ? null : AppRoutes.businessProfile,
    SessionStatus.signedIn when atLogin && adminMode.inAdminApp =>
      AppRoutes.admin,
    SessionStatus.signedIn when atLogin =>
      _continueTo(state.uri.queryParameters['from']) ?? AppRoutes.home,
    // Not an admin, or an admin who chose "View as user": leave the admin app.
    SessionStatus.signedIn when atAdmin && !adminMode.inAdminApp =>
      AppRoutes.home,
    SessionStatus.signedIn
        when !atAdmin && !atOnboarding && !atDeepLink && adminMode.inAdminApp =>
      AppRoutes.admin,
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
