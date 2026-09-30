import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../features/account/presentation/profile_cubit.dart';
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

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Stars on any tab need the watchlist; Home and More need the profile.
    context.read<ProfileCubit>().ensureLoaded();
    context.read<WatchlistCubit>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shell = widget.shell;
    return Scaffold(
      body: shell,
      bottomNavigationBar: MbBottomNav(
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
