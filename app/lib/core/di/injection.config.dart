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
import 'package:mol_bhav/core/session/session_manager.dart' as _i115;
import 'package:mol_bhav/core/session/token_refresher.dart' as _i444;
import 'package:mol_bhav/core/storage/token_storage.dart' as _i411;
import 'package:mol_bhav/core/utils/countdown.dart' as _i1044;
import 'package:mol_bhav/features/account/data/account_data.dart' as _i968;
import 'package:mol_bhav/features/account/domain/account.dart' as _i695;
import 'package:mol_bhav/features/account/presentation/account_cubits.dart'
    as _i955;
import 'package:mol_bhav/features/alerts/data/alerts_data.dart' as _i89;
import 'package:mol_bhav/features/alerts/domain/alerts.dart' as _i1045;
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
import 'package:mol_bhav/features/home/data/home_data.dart' as _i64;
import 'package:mol_bhav/features/home/domain/home_repository.dart' as _i599;
import 'package:mol_bhav/features/home/presentation/home_cubit.dart' as _i197;
import 'package:mol_bhav/features/markets/data/markets_data.dart' as _i217;
import 'package:mol_bhav/features/markets/domain/markets_repository.dart'
    as _i806;
import 'package:mol_bhav/features/markets/presentation/markets_cubits.dart'
    as _i333;
import 'package:mol_bhav/features/onboarding/data/datasources/onboarding_remote_data_source.dart'
    as _i298;
import 'package:mol_bhav/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i339;
import 'package:mol_bhav/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i417;
import 'package:mol_bhav/features/onboarding/domain/usecases/onboarding_usecases.dart'
    as _i178;
import 'package:mol_bhav/features/onboarding/presentation/cubit/business_profile_cubit.dart'
    as _i976;
import 'package:mol_bhav/features/onboarding/presentation/cubit/select_category_cubit.dart'
    as _i1019;
import 'package:mol_bhav/features/tools/data/tools_data.dart' as _i844;
import 'package:mol_bhav/features/tools/domain/tools.dart' as _i17;
import 'package:mol_bhav/features/tools/presentation/tools_cubits.dart'
    as _i825;
import 'package:mol_bhav/features/watchlist/data/watchlist_data.dart' as _i587;
import 'package:mol_bhav/features/watchlist/domain/watchlist.dart' as _i887;
import 'package:mol_bhav/features/watchlist/presentation/watchlist_page.dart'
    as _i555;
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
    gh.lazySingleton<_i411.TokenStorage>(
      () => _i411.TokenStorage(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i444.TokenRefresher>(() => _i444.PendingTokenRefresher());
    gh.lazySingleton<_i98.LocaleRepository>(
      () => _i98.LocaleRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i243.LocaleCubit>(
      () => _i243.LocaleCubit(gh<_i98.LocaleRepository>()),
    );
    gh.lazySingleton<_i756.ResponseCache>(
      () => _i756.ResponseCache(
        gh<_i460.SharedPreferences>(),
        gh<_i98.LocaleRepository>(),
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
    gh.lazySingleton<_i64.HomeRemoteDataSource>(
      () => _i64.DioHomeRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i217.MarketsRemoteDataSource>(
      () => _i217.DioMarketsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i875.AuthRemoteDataSource>(
      () => _i875.DioAuthRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i298.OnboardingRemoteDataSource>(
      () => _i298.DioOnboardingRemoteDataSource(gh<_i361.Dio>()),
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
    gh.lazySingleton<_i844.ToolsRemoteDataSource>(
      () => _i844.DioToolsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i587.WatchlistRemoteDataSource>(
      () => _i587.DioWatchlistRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1045.AlertsRepository>(
      () => _i89.AlertsRepositoryImpl(gh<_i89.AlertsRemoteDataSource>()),
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
    gh.lazySingleton<_i417.OnboardingRepository>(
      () => _i339.OnboardingRepositoryImpl(
        gh<_i298.OnboardingRemoteDataSource>(),
        gh<_i115.SessionManager>(),
      ),
    );
    gh.lazySingleton<_i599.HomeRepository>(
      () => _i64.HomeRepositoryImpl(
        gh<_i64.HomeRemoteDataSource>(),
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
    gh.lazySingleton<_i17.ToolsRepository>(
      () => _i844.ToolsRepositoryImpl(gh<_i844.ToolsRemoteDataSource>()),
    );
    gh.factory<_i969.RequestOtp>(
      () => _i969.RequestOtp(gh<_i696.AuthRepository>()),
    );
    gh.factory<_i445.VerifyOtp>(
      () => _i445.VerifyOtp(gh<_i696.AuthRepository>()),
    );
    gh.factoryParam<_i245.OtpCubit, _i769.OtpChallenge, dynamic>(
      (challenge, _) => _i245.OtpCubit(
        challenge,
        gh<_i445.VerifyOtp>(),
        gh<_i969.RequestOtp>(),
        gh<_i1044.Countdown>(),
      ),
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
    gh.factory<_i887.GetWatchlist>(
      () => _i887.GetWatchlist(gh<_i887.WatchlistRepository>()),
    );
    gh.factory<_i644.CreateAlertCubit>(
      () => _i644.CreateAlertCubit(
        gh<_i1045.GetAlertOptions>(),
        gh<_i1045.GetCurrentPrice>(),
        gh<_i1045.CreateAlert>(),
      ),
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
    gh.factory<_i178.SaveCategories>(
      () => _i178.SaveCategories(gh<_i417.OnboardingRepository>()),
    );
    gh.factory<_i555.WatchlistCubit>(
      () => _i555.WatchlistCubit(gh<_i887.GetWatchlist>()),
    );
    gh.lazySingleton<_i695.AccountRepository>(
      () => _i968.AccountRepositoryImpl(
        gh<_i968.AccountRemoteDataSource>(),
        gh<_i115.SessionManager>(),
      ),
    );
    gh.factory<_i1019.SelectCategoryCubit>(
      () => _i1019.SelectCategoryCubit(
        gh<_i178.GetCategories>(),
        gh<_i178.SaveCategories>(),
      ),
    );
    gh.factory<_i644.AlertsCubit>(
      () => _i644.AlertsCubit(gh<_i1045.GetAlerts>()),
    );
    gh.factory<_i17.GetEstimatorOptions>(
      () => _i17.GetEstimatorOptions(gh<_i17.ToolsRepository>()),
    );
    gh.factory<_i17.CalculateEstimate>(
      () => _i17.CalculateEstimate(gh<_i17.ToolsRepository>()),
    );
    gh.factory<_i17.SaveEstimate>(
      () => _i17.SaveEstimate(gh<_i17.ToolsRepository>()),
    );
    gh.factory<_i17.GetReports>(
      () => _i17.GetReports(gh<_i17.ToolsRepository>()),
    );
    gh.factory<_i599.GetHomeDashboard>(
      () => _i599.GetHomeDashboard(gh<_i599.HomeRepository>()),
    );
    gh.factory<_i333.MarketComparisonCubit>(
      () => _i333.MarketComparisonCubit(
        gh<_i806.GetCommodities>(),
        gh<_i806.GetMarketComparison>(),
      ),
    );
    gh.factory<_i597.LoginCubit>(
      () => _i597.LoginCubit(gh<_i969.RequestOtp>()),
    );
    gh.factory<_i825.ReportsCubit>(
      () => _i825.ReportsCubit(gh<_i17.GetReports>()),
    );
    gh.factory<_i976.BusinessProfileCubit>(
      () => _i976.BusinessProfileCubit(
        gh<_i178.GetProfileOptions>(),
        gh<_i178.GetDistricts>(),
        gh<_i178.SaveBusinessProfile>(),
        gh<_i98.LocaleRepository>(),
      ),
    );
    gh.factory<_i197.HomeCubit>(
      () => _i197.HomeCubit(gh<_i599.GetHomeDashboard>()),
    );
    gh.factory<_i825.CostEstimatorCubit>(
      () => _i825.CostEstimatorCubit(
        gh<_i17.GetEstimatorOptions>(),
        gh<_i17.CalculateEstimate>(),
        gh<_i17.SaveEstimate>(),
      ),
    );
    gh.factory<_i695.GetAccountProfile>(
      () => _i695.GetAccountProfile(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.UpdateNotifications>(
      () => _i695.UpdateNotifications(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.GetPlans>(
      () => _i695.GetPlans(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i695.SignOut>(
      () => _i695.SignOut(gh<_i695.AccountRepository>()),
    );
    gh.factory<_i955.MoreCubit>(
      () => _i955.MoreCubit(
        gh<_i695.GetAccountProfile>(),
        gh<_i695.UpdateNotifications>(),
        gh<_i695.SignOut>(),
      ),
    );
    gh.factory<_i955.SubscriptionCubit>(
      () => _i955.SubscriptionCubit(gh<_i695.GetPlans>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i678.RegisterModule {}
