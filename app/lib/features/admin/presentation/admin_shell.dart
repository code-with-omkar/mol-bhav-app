import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/mb_bottom_nav.dart';
import '../../../shared/widgets/mb_icons.dart';

/// The admin app's frame: its own bottom navigation, separate from the user
/// app's tabs.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

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
          MbNavItem(icon: MbIcons.report, label: l10n.adminTabDashboard),
          MbNavItem(icon: MbIcons.trend, label: l10n.adminTabAds),
          MbNavItem(icon: MbIcons.user, label: l10n.adminTabUsers),
          MbNavItem(icon: MbIcons.settings, label: l10n.adminTabApp),
        ],
      ),
    );
  }
}
