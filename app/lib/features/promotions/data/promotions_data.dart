import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/promotions.dart';

/// Sponsored cards:
///
/// - `GET /promotions?placement=HomeFeed` → `{ promotion: {…} | null }`
/// - `POST /promotions/events` `{ events: [{ campaignId, type }] }` → 204
///
/// Never cached: the server rotates sponsors and enforces daily caps.
@LazySingleton(as: PromotionsRepository)
class PromotionsRepositoryImpl implements PromotionsRepository {
  PromotionsRepositoryImpl(this._dio);

  final Dio _dio;

  static const _base = '/promotions';

  @override
  Future<Result<Promotion?>> getPromotion(PromotionPlacement placement) =>
      runApiCall(() async {
        final body = (await _dio.get<Map<String, dynamic>>(
          _base,
          queryParameters: {'placement': placementName(placement)},
        )).data!;
        final json = body.objOrNull('promotion');
        return json == null ? null : parsePromotion(json);
      });

  @override
  Future<Result<void>> recordEvents(List<PromotionEvent> events) => runApiCall(
    () => _dio.post<void>(
      '$_base/events',
      data: {
        'events': [
          for (final e in events)
            {
              'campaignId': e.campaignId,
              'type': switch (e.type) {
                PromotionEventType.impression => 'Impression',
                PromotionEventType.click => 'Click',
              },
            },
        ],
      },
    ),
  );

  static String placementName(PromotionPlacement placement) =>
      switch (placement) {
        PromotionPlacement.homeFeed => 'HomeFeed',
        PromotionPlacement.mandiPrices => 'MandiPrices',
        PromotionPlacement.marketComparison => 'MarketComparison',
      };

  /// `null` when the link isn't https — never hand anything else to the OS.
  static Promotion? parsePromotion(Map<String, dynamic> j) {
    final cta = _https(j.strOrNull('ctaUrl'));
    if (cta == null) return null;
    return Promotion(
      campaignId: j.str('campaignId'),
      advertiserName: j.str('advertiserName'),
      title: j.str('title'),
      body: j.str('body'),
      ctaLabel: j.str('ctaLabel'),
      ctaUrl: cta,
      imageUrl: _https(j.strOrNull('imageUrl')),
    );
  }

  static Uri? _https(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.isScheme('https') && uri.host.isNotEmpty
        ? uri
        : null;
  }
}
