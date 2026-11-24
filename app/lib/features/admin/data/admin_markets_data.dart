import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_markets.dart';

/// `POST /admin/market/feed-markets/import`.
@LazySingleton(as: AdminMarketsRepository)
class AdminMarketsRepositoryImpl implements AdminMarketsRepository {
  AdminMarketsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ImportMarketsResult>> importFeedMarkets({
    required String sourceId,
    required String state,
    required List<String> markets,
  }) => runApiCall(() async {
    final j = (await _dio.post<Map<String, dynamic>>(
      '/admin/market/feed-markets/import',
      data: {'priceSourceId': sourceId, 'state': state, 'markets': markets},
    )).data!;
    return parse(j);
  });

  @override
  Future<Result<ImportAllMarketsResult>> importAllFeedMarkets({
    required String sourceId,
  }) => runApiCall(() async {
    final j = (await _dio.post<Map<String, dynamic>>(
      '/admin/market/feed-markets/import-all',
      data: {'priceSourceId': sourceId},
      // Over a thousand markets are added in one go, so allow it time.
      options: Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    )).data!;
    return ImportAllMarketsResult(
      statesCreated: j.integer('statesCreated'),
      marketsCreated: j.integer('marketsCreated'),
      alreadyInCatalog: j.integer('alreadyInCatalog'),
      other: j.integer('other'),
    );
  });

  static ImportMarketsResult parse(Map<String, dynamic> j) =>
      ImportMarketsResult(
        created: j.integer('created'),
        skipped: j.list(
          'skipped',
          (s) => SkippedMarket(
            market: s.str('market'),
            reason: FeedMarketSkipReason.fromWire(s.str('reason')),
          ),
        ),
      );
}
