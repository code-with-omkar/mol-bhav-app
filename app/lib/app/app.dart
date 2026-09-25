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
import '../core/theme/app_theme.dart';

class MolBhavApp extends StatefulWidget {
  const MolBhavApp({super.key});

  @override
  State<MolBhavApp> createState() => _MolBhavAppState();
}

class _MolBhavAppState extends State<MolBhavApp> {
  final GoRouter _router = createAppRouter(getIt<SessionManager>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<LocaleCubit>(),
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
