import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/category_visuals.dart';
import '../../../shared/widgets/mb_category_card.dart';
import '../../../shared/widgets/mb_hero_header.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../app_features/domain/app_features.dart';
import '../../app_features/presentation/feature_switches_cubit.dart';
import '../../promotions/domain/promotions.dart';
import '../../promotions/presentation/ad_slot.dart';
import '../domain/home_entities.dart';
import '../../weather/presentation/weather_cubit.dart';
import 'home_cubit.dart';
import 'home_opportunity_slider.dart';
import 'home_weather.dart';

/// Category-aware dashboard: Market → Compare → Opportunity → Action.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, DataState<HomeDashboard>>(
      builder: (context, state) {
        final data = state.data;
        return Scaffold(
          body: switch (state.status) {
            _ when data != null => MbRevalidating(
              active: state.isRevalidating,
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: _Dashboard(data: data),
              ),
            ),
            LoadStatus.failure => SafeArea(
              child: MbErrorView(
                failure: state.failure!,
                onRetry: context.read<HomeCubit>().retry,
              ),
            ),
            _ => const MbLoadingView(),
          },
        );
      },
    );
  }

  /// Dashboard plus the forecast, when a station is known (refreshing
  /// without one would raise the permission prompt from Home).
  static Future<void> _refresh(BuildContext context) {
    final weather = context.read<WeatherCubit>();
    return Future.wait([
      context.read<HomeCubit>().refresh(),
      if (weather.state.station != null) weather.refreshWeather(),
    ]);
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data});

  final HomeDashboard data;

  /// `Caterer · Pune, Maharashtra`, skipping whatever isn't set.
  String? _chip(BuildContext context) {
    final district = data.districtName, state = data.stateName;
    final place = district.isNotEmpty && state.isNotEmpty
        ? context.l10n.placeLine(district, state)
        : district.isNotEmpty
        ? district
        : state;
    final parts = [data.businessType, place].where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = context.l10n;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final tops = data.topOpportunities;
    const gap = SizedBox(height: MbSpacing.s4);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeWeatherHero(
            onOpenWeather: () => context.go(AppRoutes.weather),
            header: (background) => MbHeroHeader(
              name: data.userName,
              greeting: _greeting(context),
              chip: _chip(context),
              alertsLabel: l10n.alertsLabel,
              unread: data.hasUnreadAlerts,
              onAlerts: () => context.go(AppRoutes.alerts),
              background: background,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -MbHeroHeader.overlap),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(MbRadius.xl),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                MbSpacing.s4,
                MbSpacing.s5,
                MbSpacing.s4,
                MbSpacing.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accounts created without a name (e.g. before the name
                  // field, or claimed with a password) get a way to add one.
                  if (data.userName.isEmpty) ...[
                    MbGroup(
                      children: [
                        MbListItem(
                          icon: MbIcons.user,
                          title: l10n.addYourName,
                          onTap: () =>
                              context.push<bool>(AppRoutes.editProfile),
                        ),
                      ],
                    ),
                    gap,
                  ],
                  const _QuickActions(),
                  gap,
                  MbSectionHeader(title: l10n.homeBuyingToday),
                  gap,
                  _CategoryGrid(categories: data.categories),
                  gap,
                  MbSectionHeader(
                    title: l10n.homeTopOpportunities,
                    actionLabel: l10n.viewAll,
                    onAction: () => context.go(AppRoutes.alerts),
                  ),
                  gap,
                  if (tops.isEmpty)
                    Text(
                      l10n.homeNoOpportunity,
                      style: context.mbText.body.copyWith(color: c.inkMuted),
                    )
                  else
                    HomeOpportunitySlider(items: tops),
                  gap,
                  const AdSlot(placement: PromotionPlacement.homeFeed),
                  MbSectionHeader(
                    title: l10n.homeMyWatchlist,
                    actionLabel: l10n.viewAll,
                    onAction: () => context.go(AppRoutes.watchlist),
                  ),
                  gap,
                  if (data.watchlist.isEmpty)
                    Text(
                      l10n.watchlistEmpty,
                      style: context.mbText.body.copyWith(color: c.inkMuted),
                    )
                  else
                    MbGroup(
                      children: [
                        for (final item in data.watchlist)
                          MbPriceRow(
                            thumb: categoryIcon(item.categoryCode),
                            thumbTone: categoryTint(item.categoryCode),
                            name: item.name,
                            price: formatInr(item.price),
                            unit: item.unit,
                            percent: item.percent,
                            onTap: () => context.go(
                              item.marketId.isEmpty
                                  ? AppRoutes.marketsFor(
                                      commodityId: item.commodityId,
                                    )
                                  : AppRoutes.trendsFor(
                                      item.commodityId,
                                      item.marketId,
                                    ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < categories.length; i += 2) {
      final pair = categories.skip(i).take(2).toList();
      if (i > 0) rows.add(const SizedBox(height: MbSpacing.s3));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < 2; j++) ...[
                if (j > 0) const SizedBox(width: MbSpacing.s3),
                Expanded(
                  child: j < pair.length
                      ? _tile(context, pair[j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _tile(BuildContext context, HomeCategory category) {
    return MbCategoryTile(
      title: category.name,
      subtitle: category.highlights.isEmpty
          ? null
          : category.highlights.take(2).join(' · '),
      icon: categoryIcon(category.code),
      tone: categoryTone(category.code),
      onTap: () =>
          context.go(AppRoutes.marketsFor(categoryCode: category.code)),
    );
  }
}

/// Shortcuts under the hero to tools that otherwise sit in More.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      if (context.featureOn(AppFeature.costEstimator))
        (
          MbIcons.estimator,
          l10n.quickCostEstimate,
          () => context.go(AppRoutes.costEstimator),
        ),
      if (context.featureOn(AppFeature.reports))
        (
          MbIcons.report,
          l10n.reportsTitle,
          () => context.go(AppRoutes.reports),
        ),
      (
        MbIcons.compare,
        l10n.compareMarkets,
        () => context.go(AppRoutes.markets),
      ),
      (
        MbIcons.plus,
        l10n.addToWatchlist,
        () => context.push(AppRoutes.watchlistAdd),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: _QuickAction(icon: icon, label: label, onTap: onTap),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final MbIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MbRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: MbSpacing.s2,
            horizontal: 2,
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceGreen,
                  borderRadius: BorderRadius.circular(MbRadius.md),
                ),
                child: MbIcon(icon, size: 22, color: c.primaryText),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.mbText.caption.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
