import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

enum CampaignState {
  draft,
  active,
  paused,
  ended;

  /// Unknown values read as [draft] (never served), the safe label.
  static CampaignState fromWire(String value) => CampaignState.values
      .firstWhere((s) => s.name == value.toLowerCase(), orElse: () => draft);
}

/// An API placement name as words: `MarketComparison` → `Market Comparison`.
String placementName(String placement) =>
    placement.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');

/// Delivery for one place in the app (home feed, mandi prices, …), added up
/// from its campaigns.
class PlacementPerformance extends Equatable {
  const PlacementPerformance({
    required this.placement,
    required this.campaigns,
    required this.impressions,
    required this.clicks,
  });

  final String placement;

  /// How many campaigns target this placement.
  final int campaigns;
  final int impressions;
  final int clicks;

  String get label => placementName(placement);

  /// Clicks per hundred impressions; 0 when nothing was shown.
  double get clickRatePercent =>
      impressions == 0 ? 0 : clicks * 100 / impressions;

  @override
  List<Object?> get props => [placement, campaigns, impressions, clicks];
}

/// One campaign's delivery over the chosen range.
class CampaignPerformance extends Equatable {
  const CampaignPerformance({
    required this.id,
    required this.name,
    required this.advertiserName,
    required this.placement,
    required this.status,
    required this.impressions,
    required this.clicks,
    required this.clickRatePercent,
  });

  final String id;
  final String name;
  final String advertiserName;

  /// API name, e.g. `HomeFeed`; shown split into words.
  final String placement;
  final CampaignState status;
  final int impressions;
  final int clicks;
  final double clickRatePercent;

  /// `HomeFeed` → `Home Feed`.
  String get placementLabel => placementName(placement);

  @override
  List<Object?> get props => [
    id,
    name,
    advertiserName,
    placement,
    status,
    impressions,
    clicks,
    clickRatePercent,
  ];
}

class AdsDay extends Equatable {
  const AdsDay({
    required this.day,
    required this.impressions,
    required this.clicks,
  });

  final DateTime day;
  final int impressions;
  final int clicks;

  /// Clicks per hundred impressions; 0 when nothing was shown.
  double get clickRatePercent =>
      impressions == 0 ? 0 : clicks * 100 / impressions;

  @override
  List<Object?> get props => [day, impressions, clicks];
}

/// Percent change from [previous] to [current]; null when there is nothing to
/// compare with (a zero base).
double? percentChange(num current, num previous) =>
    previous == 0 ? null : (current - previous) * 100 / previous;

/// Sponsored-ad delivery across all campaigns for a date range.
class AdsOverview extends Equatable {
  const AdsOverview({
    required this.from,
    required this.to,
    required this.impressions,
    required this.clicks,
    required this.clickRatePercent,
    required this.campaigns,
    required this.daily,
    this.previous,
  });

  /// The same figures for the range just before this one, when they could be
  /// loaded; the screens then show the change.
  final AdsOverview? previous;

  AdsOverview withPrevious(AdsOverview? previous) => AdsOverview(
    from: from,
    to: to,
    impressions: impressions,
    clicks: clicks,
    clickRatePercent: clickRatePercent,
    campaigns: campaigns,
    daily: daily,
    previous: previous,
  );

  /// The campaigns added up per placement, most clicks first (then most
  /// impressions). Placements with no campaign are not listed.
  List<PlacementPerformance> get byPlacement {
    final totals = <String, List<int>>{}; // campaigns, impressions, clicks
    for (final c in campaigns) {
      final t = totals.putIfAbsent(c.placement, () => [0, 0, 0]);
      t[0] += 1;
      t[1] += c.impressions;
      t[2] += c.clicks;
    }
    return [
      for (final e in totals.entries)
        PlacementPerformance(
          placement: e.key,
          campaigns: e.value[0],
          impressions: e.value[1],
          clicks: e.value[2],
        ),
    ]..sort((a, b) {
      final byClicks = b.clicks.compareTo(a.clicks);
      return byClicks != 0 ? byClicks : b.impressions.compareTo(a.impressions);
    });
  }

  /// [id]'s figures in the previous range, if it was in the list then.
  CampaignPerformance? previousCampaign(String id) {
    for (final c in previous?.campaigns ?? const <CampaignPerformance>[]) {
      if (c.id == id) return c;
    }
    return null;
  }

  final DateTime from;
  final DateTime to;
  final int impressions;
  final int clicks;
  final double clickRatePercent;

  /// Most clicks first; campaigns with no delivery are included.
  final List<CampaignPerformance> campaigns;
  final List<AdsDay> daily;

  @override
  List<Object?> get props => [
    from,
    to,
    impressions,
    clicks,
    clickRatePercent,
    campaigns,
    daily,
    previous,
  ];
}

abstract interface class AdminAdsRepository {
  /// Delivery for the last [days] days (IST), ending today, with the [days]
  /// days before them as [AdsOverview.previous] (left out if that load fails).
  Future<Result<AdsOverview>> getOverview({required int days});

  /// One campaign's delivery per day for the last [days] days (IST), oldest first.
  Future<Result<List<AdsDay>>> getCampaignDaily({
    required String campaignId,
    required int days,
  });
}
