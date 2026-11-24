import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/admin_ads.dart';
import '../domain/admin_campaigns.dart';
import 'admin_campaign_list_cubit.dart';

/// "Home feed", "Mandi prices", … in the app's language.
String adPlacementLabel(AppLocalizations l10n, AdPlacement placement) =>
    switch (placement) {
      AdPlacement.homeFeed => l10n.adminPlacementHomeFeed,
      AdPlacement.mandiPrices => l10n.adminPlacementMandiPrices,
      AdPlacement.marketComparison => l10n.adminPlacementMarketComparison,
    };

/// "Draft", "Active", … in the app's language.
String campaignStateLabel(AppLocalizations l10n, CampaignState state) =>
    switch (state) {
      CampaignState.draft => l10n.campaignStatusDraft,
      CampaignState.active => l10n.campaignStatusActive,
      CampaignState.paused => l10n.campaignStatusPaused,
      CampaignState.ended => l10n.campaignStatusEnded,
    };

/// Every ad campaign, newest first, filtered by state. Tap one to edit it (or
/// activate, pause or end it); the button below starts a new one.
class AdminCampaignListPage extends StatefulWidget {
  const AdminCampaignListPage({super.key});

  @override
  State<AdminCampaignListPage> createState() => _AdminCampaignListPageState();
}

class _AdminCampaignListPageState extends State<AdminCampaignListPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminCampaignListCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(String route, {AdminCampaign? campaign}) async {
    final cubit = context.read<AdminCampaignListCubit>();
    final changed = await context.push<bool>(route, extra: campaign);
    // A new, edited or re-stated campaign changes the list.
    if (changed ?? false) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminCampaignListCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminCampaignsTitle),
      body: Column(
        children: [
          BlocBuilder<AdminCampaignListCubit, AdminCampaignListState>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.fromLTRB(
                MbSpacing.s4,
                MbSpacing.s3,
                MbSpacing.s4,
                MbSpacing.s2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: MbSpacing.s2,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.filterAll),
                      selected: state.filter == null,
                      onSelected: (_) => cubit.setFilter(null),
                    ),
                    for (final s in CampaignState.values)
                      ChoiceChip(
                        label: Text(campaignStateLabel(l10n, s)),
                        selected: state.filter == s,
                        onSelected: (_) => cubit.setFilter(s),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminCampaignListCubit, AdminCampaignListState>(
              builder: (context, state) {
                if (state.campaigns.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminCampaignsEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount:
                        state.campaigns.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.campaigns.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _CampaignRow(
                            campaign: state.campaigns[i],
                            onTap: () => _open(
                              AppRoutes.adminCampaignEdit(
                                state.campaigns[i].id,
                              ),
                              campaign: state.campaigns[i],
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminCampaignsNew,
            block: true,
            onPressed: () => _open(AppRoutes.adminCampaignNew),
          ),
        ),
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign, required this.onTap});

  final AdminCampaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: t.title.copyWith(color: c.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: MbSpacing.s2),
                MbBadge(
                  label: campaignStateLabel(l10n, campaign.status),
                  tone: campaign.status == CampaignState.active
                      ? MbBadgeTone.best
                      : MbBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: MbSpacing.s1),
            Text(
              '${campaign.advertiserName} · '
              '${adPlacementLabel(l10n, campaign.placement)}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            Text(
              '${day.format(campaign.startsAt.toLocal())} – '
              '${day.format(campaign.endsAt.toLocal())}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
