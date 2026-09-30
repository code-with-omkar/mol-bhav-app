// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mol_bhav/core/cache/response_cache.dart' as _i756;
import 'package:mol_bhav/core/di/register_module.dart' as _i678;
import 'package:mol_bhav/core/locale/locale_cubit.dart' as _i243;
import 'package:mol_bhav/core/locale/locale_repository.dart' as _i98;
import 'package:mol_bhav/core/notifications/notification_service.dart' as _i552;
import 'package:mol_bhav/core/payments/razorpay_service.dart' as _i923;
import 'package:mol_bhav/core/session/session_manager.dart' as _i115;
import 'package:mol_bhav/core/session/token_refresher.dart' as _i444;
import 'package:mol_bhav/core/session/token_renewal.dart' as _i550;
import 'package:mol_bhav/core/storage/token_storage.dart' as _i411;
import 'package:mol_bhav/core/utils/countdown.dart' as _i1044;
import 'package:mol_bhav/features/account/data/account_data.dart' as _i968;
import 'package:mol_bhav/features/account/domain/account.dart' as _i695;
import 'package:mol_bhav/features/account/presentation/account_cubits.dart'
    as _i955;
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart'
    as _i736;
import 'package:mol_bhav/features/alerts/data/alerts_data.dart' as _i89;
import 'package:mol_bhav/features/alerts/domain/alerts.dart' as _i1045;
import 'package:mol_bhav/features/alerts/presentation/alert_rules_cubit.dart'
    as _i352;
import 'package:mol_bhav/features/alerts/presentation/alerts_cubits.dart'
    as _i644;
import 'package:mol_bhav/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i875;
import 'package:mol_bhav/features/auth/data/repositories/auth_repository_impl.dart'
    as _i154;
import 'package:mol_bhav/features/auth/domain/entities/otp_challenge.dart'
    as _i769;
import 'package:mol_bhav/features/auth/domain/repositories/auth_repository.dart'
    as _i696;
import 'package:mol_bhav/features/auth/domain/usecases/request_otp.dart'
    as _i969;
import 'package:mol_bhav/features/auth/domain/usecases/verify_otp.dart'
    as _i445;
import 'package:mol_bhav/features/auth/presentation/cubit/login_cubit.dart'
    as _i597;
import 'package:mol_bhav/features/auth/presentation/cubit/otp_cubit.dart'
    as _i245;
import 'package:mol_bhav/features/billing/data/billing_data.dart' as _i196;
import 'package:mol_bhav/features/billing/domain/billing.dart' as _i690;
import 'package:mol_bhav/features/billing/presentation/cubit/coupon_cubit.dart'
    as _i627;
import 'package:mol_bhav/features/billing/presentation/cubit/plans_cubit.dart'
    as _i435;
import 'package:mol_bhav/features/billing/presentation/cubit/subscription_cubit.dart'
    as _i61;
import 'package:mol_bhav/features/catalog/data/catalog_data.dart' as _i214;
import 'package:mol_bhav/features/catalog/domain/catalog.dart' as _i169;
import 'package:mol_bhav/features/home/presentation/home_cubit.dart' as _i197;
import 'package:mol_bhav/features/markets/data/mandi_prices_data.dart' as _i216;
import 'package:mol_bhav/features/markets/data/markets_data.dart' as _i217;
import 'package:mol_bhav/features/markets/domain/mandi_prices.dart' as _i995;
import 'package:mol_bhav/features/markets/domain/markets_repository.dart'
    as _i806;
import 'package:mol_bhav/features/markets/presentation/mandi_prices_cubit.dart'
    as _i804;
import 'package:mol_bhav/features/markets/presentation/markets_cubits.dart'
    as _i333;
import 'package:mol_bhav/features/notifications/data/notification_prefs_data.dart'
    as _i234;
import 'package:mol_bhav/features/notifications/domain/notification_prefs.dart'
    as _i287;
import 'package:mol_bhav/features/notifications/presentation/notification_prefs_cubit.dart'
    as _i103;
import 'package:mol_bhav/features/onboarding/data/datasources/onboarding_remote_data_source.dart'
    as _i298;
import 'package:mol_bhav/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i340;
import 'package:mol_bhav/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i417;
import 'package:mol_bhav/features/onboarding/domain/usecases/onboarding_usecases.dart'
    as _i178;
import 'package:mol_bhav/features/onboarding/presentation/cubit/business_profile_cubit.dart'
    as _i976;
import 'package:mol_bhav/features/onboarding/presentation/cubit/select_category_cubit.dart'
    as _i1019;
import 'package:mol_bhav/features/support/data/support_data.dart' as _i551;
import 'package:mol_bhav/features/support/domain/support.dart' as _i339;
import 'package:mol_bhav/features/support/presentation/support_cubits.dart'
    as _i760;
import 'package:mol_bhav/features/tools/data/tools_data.dart' as _i844;
import 'package:mol_bhav/features/tools/domain/tools.dart' as _i17;
import 'package:mol_bhav/features/tools/presentation/tools_cubits.dart'
    as _i825;
import 'package:mol_bhav/features/watchlist/data/watchlist_data.dart' as _i587;
import 'package:mol_bhav/features/watchlist/domain/watchlist.dart' as _i887;
import 'package:mol_bhav/features/watchlist/presentation/watchlist_cubit.dart'
    as _i312;
import 'package:mol_bhav/features/watchlist/presentation/watchlist_picker.dart'
    as _i692;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.factory<_i1044.Countdown>(() => const _i1044.Countdown());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i923.RazorpayService>(() => _i923.RazorpayService());
    gh.lazySingleton<_i444.TokenRefresher>(() => _i444.DioTokenRefresher());
    gh.lazySingleton<_i411.TokenStorage>(
      () => _i411.TokenStorage(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i550.TokenRenewal>(
      () => _i550.TokenRenewal(
        gh<_i411.TokenStorage>(),
        gh<_i444.TokenRefresher>(),
      ),
    );
    gh.lazySingleton<_i98.LocaleRepository>(
      () => _i98.LocaleRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i756.ResponseCache>(
      () => _i756.ResponseCache(
        gh<_i460.SharedPreferences>(),
        gh<_i98.LocaleRepository>(),
      ),
    );
    gh.lazySingleton<_i243.LocaleCubit>(
      () => _i243.LocaleCubit(
        gh<_i98.LocaleRepository>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i115.SessionManager>(
      () => _i115.SessionManager(
        gh<_i411.TokenStorage>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(
        gh<_i411.TokenStorage>(),
        gh<_i444.TokenRefresher>(),
        gh<_i115.SessionManager>(),
        gh<_i98.LocaleRepository>(),
      ),
    );
    gh.lazySingleton<_i89.AlertsRemoteDataSource>(
      () => _i89.DioAlertsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i234.NotificationDeviceDataSource>(
      () => _i234.DioNotificationDeviceDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i995.MandiPricesRepository>(
      () => _i216.MandiPricesRepositoryImpl(
        gh<_i361.Dio>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i169.CatalogRepository>(
      () => _i214.CatalogRepositoryImpl(
        gh<_i361.Dio>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i217.MarketsRemoteDataSource>(
      () => _i217.DioMarketsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i875.AuthRemoteDataSource>(
      () => _i875.DioAuthRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i234.NotificationPrefsRemoteDataSource>(
      () => _i234.DioNotificationPrefsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.factory<_i995.GetMandiPrices>(
      () => _i995.GetMandiPrices(gh<_i995.MandiPricesRepository>()),
    );
    gh.factory<_i692.WatchlistPickerCubit>(
      () => _i692.WatchlistPickerCubit(gh<_i169.CatalogRepository>()),
    );
    gh.lazySingleton<_i17.EstimatorRepository>(
      () => _i844.EstimatorRepositoryImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i196.BillingRemoteDataSource>(
      () => _i196.DioBillingRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i696.AuthRepository>(
      () => _i154.AuthRepositoryImpl(
        gh<_i875.AuthRemoteDataSource>(),
        gh<_i115.SessionManager>(),
      ),
    );
    gh.lazySingleton<_i968.AccountRemoteDataSource>(
      () => _i968.DioAccountRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i587.WatchlistRemoteDataSource>(
      () => _i587.DioWatchlistRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i298.OnboardingRemoteDataSource>(
      () => _i298.DioOnboardingRemoteDataSource(
        gh<_i361.Dio>(),
        gh<_i460.SharedPreferences>(),
        gh<_i98.LocaleRepository>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i17.ReportsRepository>(
      () => _i844.ReportsRepositoryImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i339.SupportRepository>(
      () => _i551.SupportRepositoryImpl(
        gh<_i361.Dio>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i690.BillingRepository>(
      () => _i196.BillingRepositoryImpl(
        gh<_i196.BillingRemoteDataSource>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.lazySingleton<_i552.NotificationService>(
      () => _i552.NotificationService(gh<_i234.NotificationDeviceDataSource>()),
    );
    gh.lazySingleton<_i1045.AlertsRepository>(
      () => _i89.AlertsRepositoryImpl(
        gh<_i89.AlertsRemoteDataSource>(),
        gh<_i169.CatalogRepository>(),
      ),
    );
    gh.lazySingleton<_i806.MarketsRepository>(
      () => _i217.MarketsRepositoryImpl(
        gh<_i217.MarketsRemoteDataSource>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.factory<_i1045.GetAlerts>(
      () => _i1045.GetAlerts(gh<_i1045.AlertsRepository>()),
    );
    gh.factory<_i1045.GetAlertOptions>(
      () => _i1045.GetAlertOptions(gh<_i1045.AlertsRepository>()),
    );
    gh.factory<_i1045.GetCurrentPrice>(
      () => _i1045.GetCurrentPrice(gh<_i1045.AlertsRepository>()),
    );
    gh.factory<_i1045.CreateAlert>(
      () => _i1045.CreateAlert(gh<_i1045.AlertsRepository>()),
    );
    gh.factory<_i352.AlertRulesCubit>(
      () => _i352.AlertRulesCubit(gh<_i1045.AlertsRepository>()),
    );
    gh.lazySingleton<_i417.OnboardingRepository>(
      () => _i340.OnboardingRepositoryImpl(
        gh<_i298.OnboardingRemoteDataSource>(),
        gh<_i115.SessionManager>(),
      ),
    );
    gh.lazySingleton<_i287.NotificationPrefsRepository>(
      () => _i234.NotificationPrefsRepositoryImpl(
        gh<_i234.NotificationPrefsRemoteDataSource>(),
      ),
    );
    gh.factory<_i103.NotificationPrefsCubit>(
      () =>
          _i103.NotificationPrefsCubit(gh<_i287.NotificationPrefsRepository>()),
    );
    gh.lazySingleton<_i695.AccountRepository>(
      () => _i968.AccountRepositoryImpl(
        gh<_i968.AccountRemoteDataSource>(),
        gh<_i115.SessionManager>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.factory<_i806.GetCommodities>(
      () => _i806.GetCommodities(gh<_i806.MarketsRepository>()),
    );
    gh.factory<_i806.GetMarketComparison>(
      () => _i806.GetMarketComparison(gh<_i806.MarketsRepository>()),
    );
    gh.factory<_i806.GetPriceTrend>(
      () => _i806.GetPriceTrend(gh<_i806.MarketsRepository>()),
    );
    gh.factory<_i806.GetBuyingOpportunity>(
      () => _i806.GetBuyingOpportunity(gh<_i806.MarketsRepository>()),
    );
    gh.factory<_i333.BuyingOpportunityCubit>(
      () => _i333.BuyingOpportunityCubit(gh<_i806.GetBuyingOpportunity>()),
    );
    gh.factory<_i969.RequestOtp>(
      () => _i969.RequestOtp(gh<_i696.AuthRepository>()),
    );
    gh.factory<_i445.VerifyOtp>(
      () => _i445.VerifyOtp(gh<_i696.AuthRepository>()),
    );
    gh.factory<_i804.MandiPricesCubit>(
      () => _i804.MandiPricesCubit(gh<_i995.GetMandiPrices>()),
    );
    gh.factoryParam<_i245.OtpCubit, _i769.OtpChallenge, dynamic>(
      (challenge, _) => _i245.OtpCubit(
        challenge,
        gh<_i445.VerifyOtp>(),
        gh<_i969.RequestOtp>(),
        gh<_i1044.Countdown>(),
      ),
    );
    gh.factory<_i627.CouponCubit>(
      () => _i627.CouponCubit(gh<_i690.BillingRepository>()),
    );
    gh.factory<_i435.PlansCubit>(
      () => _i435.PlansCubit(gh<_i690.BillingRepository>()),
    );
    gh.lazySingleton<_i887.WatchlistRepository>(
      () => _i587.WatchlistRepositoryImpl(
        gh<_i587.WatchlistRemoteDataSource>(),
        gh<_i756.ResponseCache>(),
      ),
    );
    gh.factory<_i333.PriceTrendsCubit>(
      () => _i333.PriceTrendsCubit(gh<_i806.GetPriceTrend>()),
    );
    gh.factory<_i887.WatchWatchlist>(
      () => _i887.WatchWatchlist(gh<_i887.WatchlistRepository>()),
    );
    gh.factory<_i887.AddToWatchlist>(
      () => _i887.AddToWatchlist(gh<_i887.WatchlistRepository>()),
    );
    gh.factory<_i887.RemoveFromWatchlist>(
      () => _i887.RemoveFromWatchlist(gh<_i887.WatchlistRepository>()),
    );
    gh.factory<_i178.GetProfileOptions>(
      () => _i178.GetProfileOptions(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i178.GetDistricts>(
      () => _i178.GetDistricts(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i178.SaveBusinessProfile>(
      () => _i178.SaveBusinessProfile(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i178.GetCategories>(
      () => _i178.GetCategories(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i178.GetSavedProfile>(
      () => _i178.GetSavedProfile(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i178.SaveCategories>(
      () => _i178.SaveCategories(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i695.WatchAccountProfile>(
      () => _i695.WatchAccountProfile(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.InvalidateAccountProfile>(
      () => _i695.InvalidateAccountProfile(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.UpdateNotifications>(
      () => _i695.UpdateNotifications(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.SignOut>(
      () => _i695.SignOut(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i644.AlertsCubit>(
      () => _i644.AlertsCubit(gh<_i1045.GetAlerts>()),
    );
    gh.factory<_i339.GetSupportFaq>(
      () => _i339.GetSupportFaq(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i339.GetSupportContact>(
      () => _i339.GetSupportContact(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i339.GetSupportTickets>(
      () => _i339.GetSupportTickets(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i339.GetSupportTicket>(
      () => _i339.GetSupportTicket(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i339.CreateSupportTicket>(
      () => _i339.CreateSupportTicket(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i339.ReplyToSupportTicket>(
      () => _i339.ReplyToSupportTicket(gh<_i339.SupportRepository>()),
    );
    gh.factory<_i760.MyTicketsCubit>(
      () => _i760.MyTicketsCubit(gh<_i339.GetSupportTickets>()),
    );
    gh.factory<_i1019.SelectCategoryCubit>(
      () => _i1019.SelectCategoryCubit(
        gh<_i178.GetCategories>(),
        gh<_i178.SaveCategories>(),
        gh<_i178.GetSavedProfile>(),
      ),
    );
    gh.factory<_i976.BusinessProfileCubit>(
      () => _i976.BusinessProfileCubit(
        gh<_i178.GetProfileOptions>(),
        gh<_i178.GetDistricts>(),
        gh<_i178.SaveBusinessProfile>(),
        gh<_i178.GetSavedProfile>(),
        gh<_i98.LocaleRepository>(),
      ),
    );
    gh.lazySingleton<_i736.ProfileCubit>(
      () => _i736.ProfileCubit(
        gh<_i695.WatchAccountProfile>(),
        gh<_i695.InvalidateAccountProfile>(),
        gh<_i115.SessionManager>(),
        gh<_i243.LocaleCubit>(),
      ),
    );
    gh.factory<_i333.MarketComparisonCubit>(
      () => _i333.MarketComparisonCubit(
        gh<_i806.GetCommodities>(),
        gh<_i806.GetMarketComparison>(),
        gh<_i169.CatalogRepository>(),
        gh<_i736.ProfileCubit>(),
      ),
    );
    gh.factory<_i760.HelpSupportCubit>(
      () => _i760.HelpSupportCubit(
        gh<_i339.GetSupportFaq>(),
        gh<_i339.GetSupportContact>(),
      ),
    );
    gh.factory<_i955.MoreCubit>(
      () => _i955.MoreCubit(
        gh<_i736.ProfileCubit>(),
        gh<_i695.SignOut>(),
        gh<_i552.NotificationService>(),
      ),
    );
    gh.factory<_i760.TicketThreadCubit>(
      () => _i760.TicketThreadCubit(
        gh<_i339.GetSupportTicket>(),
        gh<_i339.ReplyToSupportTicket>(),
      ),
    );
    gh.factory<_i597.LoginCubit>(
      () => _i597.LoginCubit(gh<_i969.RequestOtp>()),
    );
    gh.factory<_i760.RaiseTicketCubit>(
      () => _i760.RaiseTicketCubit(gh<_i339.CreateSupportTicket>()),
    );
    gh.factory<_i61.SubscriptionCubit>(
      () => _i61.SubscriptionCubit(
        gh<_i690.BillingRepository>(),
        gh<_i736.ProfileCubit>(),
        gh<_i550.TokenRenewal>(),
      ),
    );
    gh.factory<_i825.ReportsCubit>(
      () => _i825.ReportsCubit(
        gh<_i17.ReportsRepository>(),
        gh<_i169.CatalogRepository>(),
        gh<_i995.MandiPricesRepository>(),
        gh<_i736.ProfileCubit>(),
        gh<_i98.LocaleRepository>(),
      ),
    );
    gh.lazySingleton<_i312.WatchlistCubit>(
      () => _i312.WatchlistCubit(
        gh<_i887.WatchWatchlist>(),
        gh<_i887.AddToWatchlist>(),
        gh<_i887.RemoveFromWatchlist>(),
        gh<_i115.SessionManager>(),
      ),
    );
    gh.factory<_i644.CreateAlertCubit>(
      () => _i644.CreateAlertCubit(
        gh<_i1045.GetAlertOptions>(),
        gh<_i1045.GetCurrentPrice>(),
        gh<_i1045.CreateAlert>(),
        gh<_i736.ProfileCubit>(),
      ),
    );
    gh.factory<_i825.CostEstimatorCubit>(
      () => _i825.CostEstimatorCubit(
        gh<_i17.EstimatorRepository>(),
        gh<_i169.CatalogRepository>(),
        gh<_i995.MandiPricesRepository>(),
        gh<_i736.ProfileCubit>(),
      ),
    );
    gh.factory<_i197.HomeCubit>(
      () => _i197.HomeCubit(
        gh<_i736.ProfileCubit>(),
        gh<_i312.WatchlistCubit>(),
        gh<_i169.CatalogRepository>(),
        gh<_i243.LocaleCubit>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i678.RegisterModule {}
