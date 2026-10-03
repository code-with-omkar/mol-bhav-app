import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/brand.dart';
import '../core/di/injection.dart';
import '../core/l10n/l10n.dart';
import '../core/locale/app_language.dart';
import '../core/locale/locale_cubit.dart';
import '../core/router/app_router.dart';
import '../core/session/session_manager.dart';
import '../core/session/token_renewal.dart';
import '../core/theme/app_theme.dart';
import '../features/account/presentation/profile_cubit.dart';
import '../features/billing/presentation/subscription_tier_sync.dart';
import '../features/watchlist/presentation/watchlist_cubit.dart';

class MolBhavApp extends StatefulWidget {
  const MolBhavApp({super.key});

  @override
  State<MolBhavApp> createState() => _MolBhavAppState();
}

class _MolBhavAppState extends State<MolBhavApp> with WidgetsBindingObserver {
  final GoRouter _router = createAppRouter(getIt<SessionManager>());
  final SubscriptionTierSync _tierSync = SubscriptionTierSync(
    getIt<ProfileCubit>(),
    getIt<TokenRenewal>(),
    getIt<SessionManager>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A Pro subscription may have lapsed while the app was in the background.
    if (state == AppLifecycleState.resumed) _tierSync.recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // App-wide cubits: every screen sees the same language, profile and
    // watchlist, so a change on one screen shows on all.
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<LocaleCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
        BlocProvider.value(value: getIt<WatchlistCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, AppLanguage>(
        builder: (context, language) => MaterialApp.router(
          title: Brand.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: language.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
