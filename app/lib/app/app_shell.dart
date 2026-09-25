import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../shared/widgets/mb_bottom_nav.dart';
import '../shared/widgets/mb_icons.dart';

/// Root tabs with the bottom navigation: Home, Markets, Watchlist,
/// Opportunities (alerts), More.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          MbNavItem(icon: MbIcons.opportunity, label: l10n.navOpportunities),
          MbNavItem(icon: MbIcons.more, label: l10n.navMore),
        ],
      ),
    );
  }
}
