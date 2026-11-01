import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../features/account/presentation/profile_cubit.dart';
import '../features/app_features/presentation/feature_switches_cubit.dart';
import '../features/app_notice/presentation/app_notice_banner.dart';
import '../features/app_notice/presentation/app_notice_cubit.dart';
import '../features/app_notice/presentation/maintenance_view.dart';
import '../features/price_status/presentation/price_data_banner.dart';
import '../features/price_status/presentation/price_data_status_cubit.dart';
import '../features/watchlist/presentation/watchlist_cubit.dart';
import '../shared/widgets/mb_bottom_nav.dart';
import '../shared/widgets/mb_icons.dart';

/// Root tabs with the bottom navigation: Home, Markets, Watchlist,
/// Opportunities (alerts), More.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  /// How often the "prices may be delayed" status is re-checked while the app
  /// is open (the feeds refresh about once a day, so this is plenty).
  static const _statusRefresh = Duration(minutes: 10);

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    // Stars on any tab need the watchlist; Home and More need the profile.
    context.read<ProfileCubit>().ensureLoaded();
    context.read<WatchlistCubit>().ensureLoaded();
    // The banner on every tab needs the price-feed status.
    final status = context.read<PriceDataStatusCubit>()..load();
    // The admin's message (a note, a warning or maintenance) rides the same
    // schedule, so a maintenance page clears soon after it is switched off.
    final notice = context.read<AppNoticeCubit>()..load();
    // Parts of the app an admin has switched off (ads, reports, estimator).
    final features = context.read<FeatureSwitchesCubit>()..load();
    _statusTimer = Timer.periodic(_statusRefresh, (_) {
      status.load();
      notice.load();
      features.load();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A feed may have failed (or recovered) while the app was in the background.
    if (state == AppLifecycleState.resumed) {
      context.read<PriceDataStatusCubit>().load();
      context.read<AppNoticeCubit>().load();
      context.read<FeatureSwitchesCubit>().load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shell = widget.shell;
    // While an admin has the app in maintenance the page covers everything,
    // the tabs included; the screens underneath stay mounted for when it ends.
    final blocking = context.select((AppNoticeCubit c) => c.state.blocking);
    final noticeShown = context.select(
      (AppNoticeCubit c) => c.state.showBanner,
    );
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const AppNoticeBanner(),
              // The notice banner above already clears the status bar.
              MediaQuery.removePadding(
                context: context,
                removeTop: noticeShown,
                child: const PriceDataBanner(),
              ),
              Expanded(child: shell),
            ],
          ),
          if (blocking) const Positioned.fill(child: MaintenanceView()),
        ],
      ),
      bottomNavigationBar: blocking
          ? null
          : MbBottomNav(
              currentIndex: shell.currentIndex,
              // Re-tapping the current tab returns to its first screen.
              onSelect: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              items: [
                MbNavItem(icon: MbIcons.home, label: l10n.navHome),
                MbNavItem(icon: MbIcons.markets, label: l10n.navMarkets),
                MbNavItem(icon: MbIcons.watchlist, label: l10n.navWatchlist),
                MbNavItem(icon: MbIcons.alert, label: l10n.navAlerts),
                MbNavItem(icon: MbIcons.more, label: l10n.navMore),
              ],
            ),
    );
  }
}
