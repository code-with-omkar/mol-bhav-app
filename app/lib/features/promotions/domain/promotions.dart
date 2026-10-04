import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

/// Where a sponsored card can appear. Each maps to one slot the app already
/// reserves for a native ad.
enum PromotionPlacement { homeFeed, mandiPrices, marketComparison }

/// A direct-sold sponsorship, rendered as a "Sponsored" card in the app's
/// own style. [ctaUrl] is always https — the server refuses anything else.
class Promotion extends Equatable {
  const Promotion({
    required this.campaignId,
    required this.advertiserName,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaUrl,
    this.imageUrl,
  });

  final String campaignId;
  final String advertiserName;
  final String title;
  final String body;
  final String ctaLabel;
  final Uri ctaUrl;
  final Uri? imageUrl;

  @override
  List<Object?> get props => [
    campaignId,
    advertiserName,
    title,
    body,
    ctaLabel,
    ctaUrl,
    imageUrl,
  ];
}

enum PromotionEventType { impression, click }

class PromotionEvent extends Equatable {
  const PromotionEvent(this.campaignId, this.type);

  final String campaignId;
  final PromotionEventType type;

  @override
  List<Object?> get props => [campaignId, type];
}

abstract interface class PromotionsRepository {
  /// `Ok(null)` when nothing is booked for this user and slot (or they're Pro).
  Future<Result<Promotion?>> getPromotion(PromotionPlacement placement);

  Future<Result<void>> recordEvents(List<PromotionEvent> events);
}

@injectable
class GetPromotion {
  const GetPromotion(this._repository);

  final PromotionsRepository _repository;

  Future<Result<Promotion?>> call(PromotionPlacement placement) =>
      _repository.getPromotion(placement);
}
