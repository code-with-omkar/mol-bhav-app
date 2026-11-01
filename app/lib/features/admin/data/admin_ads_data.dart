import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_ads.dart';

/// `GET /admin/promotions/stats?from=` (the end defaults to today, IST).
@LazySingleton(as: AdminAdsRepository)
class AdminAdsRepositoryImpl implements AdminAdsRepository {
  AdminAdsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AdsOverview>> getOverview({required int days}) =>
      runApiCall(() async {
        final now = DateTime.now();
        final current = _fetch(
          from: now.subtract(Duration(days: days - 1)),
          to: null,
        );
        // The same number of days straight before; only a comparison, so a
        // failure here must not hide the current figures.
        final previous = _fetch(
          from: now.subtract(Duration(days: 2 * days - 1)),
          to: now.subtract(Duration(days: days)),
        ).then<AdsOverview?>((o) => o).catchError((_) => null);
        final overview = await current;
        return overview.withPrevious(await previous);
      });

  Future<AdsOverview> _fetch({required DateTime from, DateTime? to}) async {
    final j = (await _dio.get<Map<String, dynamic>>(
      '/admin/promotions/stats',
      queryParameters: {'from': _day(from), if (to != null) 'to': _day(to)},
    )).data!;
    return parseOverview(j);
  }

  @override
  Future<Result<List<AdsDay>>> getCampaignDaily({
    required String campaignId,
    required int days,
  }) => runApiCall(() async {
    final from = DateTime.now().subtract(Duration(days: days - 1));
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/promotions/campaigns/${Uri.encodeComponent(campaignId)}/stats',
      queryParameters: {'from': _day(from)},
    )).data!;
    return [
      for (final d in rows.cast<Map<String, dynamic>>())
        AdsDay(
          day: DateTime.parse(d.str('day')),
          impressions: d.integer('impressions'),
          clicks: d.integer('clicks'),
        ),
    ];
  });

  /// `yyyy-MM-dd` — the API takes calendar dates, not instants.
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static AdsOverview parseOverview(Map<String, dynamic> j) => AdsOverview(
    from: DateTime.parse(j.str('from')),
    to: DateTime.parse(j.str('to')),
    impressions: j.integer('impressions'),
    clicks: j.integer('clicks'),
    clickRatePercent: j.number('clickRatePercent').toDouble(),
    campaigns: j.list(
      'campaigns',
      (c) => CampaignPerformance(
        id: c.str('id'),
        name: c.str('name'),
        advertiserName: c.str('advertiserName'),
        placement: c.str('placement'),
        status: CampaignState.fromWire(c.str('status')),
        impressions: c.integer('impressions'),
        clicks: c.integer('clicks'),
        clickRatePercent: c.number('clickRatePercent').toDouble(),
      ),
    ),
    daily: j.list(
      'daily',
      (d) => AdsDay(
        day: DateTime.parse(d.str('day')),
        impressions: d.integer('impressions'),
        clicks: d.integer('clicks'),
      ),
    ),
  );
}
