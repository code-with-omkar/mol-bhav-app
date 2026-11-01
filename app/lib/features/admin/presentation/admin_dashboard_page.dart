import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/session/admin_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../../core/utils/timestamps.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../core/di/injection.dart';
import '../domain/admin_dashboard.dart';
import 'admin_dashboard_cubit.dart';
import 'admin_feeds_card.dart';
import 'admin_stat_card.dart';

/// What an admin sees first: headline numbers for users, ads, the price feeds
/// and support. Pull down to refresh.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminDashboardCubit>();
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.adminDashboardTitle,
        showBack: false,
        actions: [
          MbAppBarAction(
            icon: MbIcons.user,
            label: l10n.adminSwitchToUserView,
            onPressed: () => getIt<AdminMode>().switchToUserView(),
          ),
        ],
      ),
      body: BlocBuilder<AdminDashboardCubit, DataState<AdminDashboard>>(
        builder: (context, state) {
          final data = state.data;
          if (data == null) {
            return state.status == LoadStatus.failure
                ? MbErrorView(failure: state.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                _UsersCard(users: data.users),
                const SizedBox(height: MbSpacing.s3),
                _AdsCard(ads: data.ads),
                const SizedBox(height: MbSpacing.s3),
                AdminFeedsCard(feeds: data.feeds),
                const SizedBox(height: MbSpacing.s3),
                AdminStatCard(
                  title: l10n.adminSupportTitle,
                  stats: [
                    AdminStat(l10n.adminSupportOpen, _n(data.openTickets)),
                  ],
                ),
                const SizedBox(height: MbSpacing.s3),
                Text(
                  context.updatedAt(data.generatedAt),
                  style: context.mbText.caption.copyWith(
                    color: context.mbColors.inkMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _n(num value) => NumberFormat.decimalPattern().format(value);

class _UsersCard extends StatelessWidget {
  const _UsersCard({required this.users});

  final AdminUsersSummary users;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminStatCard(
      title: l10n.adminUsersTitle,
      stats: [
        AdminStat(l10n.adminUsersTotal, _n(users.total)),
        AdminStat(l10n.adminUsersNew, _n(users.newLast7Days)),
        AdminStat(l10n.adminUsersActive, _n(users.activeLast7Days)),
        AdminStat(l10n.adminUsersPro, _n(users.pro)),
        AdminStat(l10n.adminUsersFree, _n(users.free)),
        AdminStat(l10n.adminUsersSuspended, _n(users.suspended)),
      ],
    );
  }
}

class _AdsCard extends StatelessWidget {
  const _AdsCard({required this.ads});

  final AdminAdsSummary ads;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminStatCard(
      title: l10n.adminAdsTitle,
      stats: [
        AdminStat(l10n.adminAdsClicksToday, _n(ads.clicksToday)),
        AdminStat(l10n.adminAdsImpressionsToday, _n(ads.impressionsToday)),
        AdminStat(
          l10n.adminAdsClickRate,
          '${NumberFormat('0.0').format(ads.clickRate7DaysPercent)}%',
        ),
        AdminStat(l10n.adminAdsCampaigns, _n(ads.activeCampaigns)),
        AdminStat(l10n.adminAdsRewarded, _n(ads.rewardedViews7Days)),
      ],
      note: l10n.adminAdsNote,
    );
  }
}
