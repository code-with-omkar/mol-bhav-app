import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/admin_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../domain/admin_dashboard.dart';
import 'admin_dashboard_cubit.dart';
import 'admin_feeds_card.dart';

/// App management: how the price feeds are doing, and the tools for running
/// them — schedules (which also hold the price sources) and the pull history.
/// Catalog and market editing stay in the web admin.
class AdminAppPage extends StatelessWidget {
  const AdminAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminDashboardCubit>();
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.adminAppTitle,
        showBack: false,
        actions: [
          MbAppBarAction(
            icon: MbIcons.user,
            label: l10n.adminSwitchToUserView,
            onPressed: () => getIt<AdminMode>().switchToUserView(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cubit.load,
        child: ListView(
          padding: MbSpacing.screenPadding,
          children: [
            // The entries below work without it, so a failed load just hides the card.
            BlocBuilder<AdminDashboardCubit, DataState<AdminDashboard>>(
              builder: (context, state) => switch (state.data) {
                final AdminDashboard data => Padding(
                  padding: const EdgeInsets.only(bottom: MbSpacing.s3),
                  child: AdminFeedsCard(feeds: data.feeds),
                ),
                null => const SizedBox.shrink(),
              },
            ),
            _Entry(
              title: l10n.adminTicketsTitle,
              subtitle: l10n.adminSupportSubtitle,
              onTap: () => context.go(AppRoutes.adminAppSupport),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminAuditTitle,
              subtitle: l10n.adminAuditSubtitle,
              onTap: () => context.go(AppRoutes.adminAppActivity),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminMarketsTitle,
              subtitle: l10n.adminMarketsSubtitle,
              onTap: () => context.go(AppRoutes.adminAppMarkets),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminVersionTitle,
              subtitle: l10n.adminVersionSubtitle,
              onTap: () => context.go(AppRoutes.adminAppVersion),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminFeaturesTitle,
              subtitle: l10n.adminFeaturesSubtitle,
              onTap: () => context.go(AppRoutes.adminAppFeatures),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminNoticeTitle,
              subtitle: l10n.adminNoticeSubtitle,
              onTap: () => context.go(AppRoutes.adminAppNotice),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminSchedulesTitle,
              subtitle: l10n.adminSchedulesSubtitle,
              onTap: () => context.go(AppRoutes.adminAppSchedules),
            ),
            const SizedBox(height: MbSpacing.s2),
            _Entry(
              title: l10n.adminHistoryTitle,
              subtitle: l10n.adminHistorySubtitle,
              onTap: () => context.go(AppRoutes.adminHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.title.copyWith(color: c.ink)),
                  const SizedBox(height: MbSpacing.s1),
                  Text(subtitle, style: t.caption.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
            MbIcon(MbIcons.chevronRight, size: 18, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
