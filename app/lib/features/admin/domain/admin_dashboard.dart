import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_ingestion.dart';

class AdminUsersSummary extends Equatable {
  const AdminUsersSummary({
    required this.total,
    required this.newLast7Days,
    required this.activeLast7Days,
    required this.suspended,
    required this.pro,
    required this.free,
  });

  final int total;
  final int newLast7Days;
  final int activeLast7Days;
  final int suspended;
  final int pro;
  final int free;

  @override
  List<Object?> get props => [
    total,
    newLast7Days,
    activeLast7Days,
    suspended,
    pro,
    free,
  ];
}

/// Sponsored-ad delivery plus rewarded views. AdMob banner clicks are only
/// visible in AdMob itself.
class AdminAdsSummary extends Equatable {
  const AdminAdsSummary({
    required this.impressionsToday,
    required this.clicksToday,
    required this.impressions7Days,
    required this.clicks7Days,
    required this.clickRate7DaysPercent,
    required this.activeCampaigns,
    required this.rewardedViews7Days,
  });

  final int impressionsToday;
  final int clicksToday;
  final int impressions7Days;
  final int clicks7Days;
  final double clickRate7DaysPercent;
  final int activeCampaigns;
  final int rewardedViews7Days;

  @override
  List<Object?> get props => [
    impressionsToday,
    clicksToday,
    impressions7Days,
    clicks7Days,
    clickRate7DaysPercent,
    activeCampaigns,
    rewardedViews7Days,
  ];
}

/// Health of the automatically refreshed price feeds.
class AdminFeedsSummary extends Equatable {
  const AdminFeedsSummary({
    required this.isDelayed,
    this.lastSuccessAt,
    this.lastAttemptStatus,
    this.lastAttemptAt,
  });

  final bool isDelayed;
  final DateTime? lastSuccessAt;
  final IngestionJobStatus? lastAttemptStatus;
  final DateTime? lastAttemptAt;

  @override
  List<Object?> get props => [
    isDelayed,
    lastSuccessAt,
    lastAttemptStatus,
    lastAttemptAt,
  ];
}

class AdminDashboard extends Equatable {
  const AdminDashboard({
    required this.users,
    required this.ads,
    required this.feeds,
    required this.openTickets,
    required this.generatedAt,
  });

  final AdminUsersSummary users;
  final AdminAdsSummary ads;
  final AdminFeedsSummary feeds;
  final int openTickets;
  final DateTime generatedAt;

  @override
  List<Object?> get props => [users, ads, feeds, openTickets, generatedAt];
}

abstract interface class AdminDashboardRepository {
  Future<Result<AdminDashboard>> getOverview();
}
