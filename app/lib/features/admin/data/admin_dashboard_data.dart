import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_dashboard.dart';
import '../domain/admin_ingestion.dart';

/// `GET /admin/dashboard/overview`.
@LazySingleton(as: AdminDashboardRepository)
class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AdminDashboard>> getOverview() => runApiCall(() async {
    final j = (await _dio.get<Map<String, dynamic>>(
      '/admin/dashboard/overview',
    )).data!;
    return parseDashboard(j);
  });

  static AdminDashboard parseDashboard(Map<String, dynamic> j) {
    final users = j.obj('users');
    final ads = j.obj('ads');
    final feeds = j.obj('feeds');
    final lastStatus = feeds.strOrNull('lastAttemptStatus');
    return AdminDashboard(
      users: AdminUsersSummary(
        total: users.integer('total'),
        newLast7Days: users.integer('newLast7Days'),
        activeLast7Days: users.integer('activeLast7Days'),
        suspended: users.integer('suspended'),
        pro: users.integer('pro'),
        free: users.integer('free'),
      ),
      ads: AdminAdsSummary(
        impressionsToday: ads.integer('impressionsToday'),
        clicksToday: ads.integer('clicksToday'),
        impressions7Days: ads.integer('impressions7Days'),
        clicks7Days: ads.integer('clicks7Days'),
        clickRate7DaysPercent: ads.number('clickRate7DaysPercent').toDouble(),
        activeCampaigns: ads.integer('activeCampaigns'),
        rewardedViews7Days: ads.integer('rewardedViews7Days'),
      ),
      feeds: AdminFeedsSummary(
        isDelayed: feeds.flag('isDelayed'),
        lastSuccessAt: feeds.dateOrNull('lastSuccessAtUtc'),
        lastAttemptStatus: lastStatus == null
            ? null
            : parseJobStatus(lastStatus),
        lastAttemptAt: feeds.dateOrNull('lastAttemptAtUtc'),
      ),
      openTickets: j.obj('support').integer('openTickets'),
      generatedAt: j.date('generatedAtUtc'),
    );
  }
}
