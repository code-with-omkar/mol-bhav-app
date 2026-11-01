import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// A cheaper market for a watchlist product, found by the daily scan: the
/// [best] market's price plus transport and other costs ([landedPrice]) is at
/// least 10% below the cheapest market in the user's home district.
class MarketOpportunity extends Equatable {
  const MarketOpportunity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.unit,
    required this.homeId,
    required this.homeName,
    required this.homePrice,
    required this.bestId,
    required this.bestName,
    required this.bestDistrict,
    required this.bestPrice,
    required this.landedPrice,
    required this.savingsPercent,
    required this.savingsPerUnit,
    required this.priceDate,
    required this.detectedAt,
    required this.isRead,
  });

  final String id;
  final String productId;
  final String productName;
  final String? variantName;
  final String unit;
  final String homeId;
  final String homeName;
  final num homePrice;
  final String bestId;
  final String bestName;
  final String bestDistrict;
  final num bestPrice;
  final num landedPrice;
  final num savingsPercent;
  final num savingsPerUnit;
  final DateTime priceDate;
  final DateTime detectedAt;
  final bool isRead;

  /// `Onion (Red)`, or just the product when no variant.
  String get displayName =>
      variantName == null ? productName : '$productName ($variantName)';

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    variantName,
    unit,
    homeId,
    homeName,
    homePrice,
    bestId,
    bestName,
    bestDistrict,
    bestPrice,
    landedPrice,
    savingsPercent,
    savingsPerUnit,
    priceDate,
    detectedAt,
    isRead,
  ];
}

/// One market's current price for the opportunity's product/variant.
class OpportunityMarket extends Equatable {
  const OpportunityMarket({
    required this.id,
    required this.name,
    required this.district,
    required this.price,
    required this.landedPrice,
    required this.isHomeDistrict,
  });

  final String id;
  final String name;
  final String district;
  final num price;

  /// [price] plus costs; equal to [price] in the home district.
  final num landedPrice;
  final bool isHomeDistrict;

  @override
  List<Object?> get props => [
    id,
    name,
    district,
    price,
    landedPrice,
    isHomeDistrict,
  ];
}

class OpportunityDetail extends Equatable {
  const OpportunityDetail({
    required this.opportunity,
    required this.markets,
    required this.referenceQuantity,
  });

  final MarketOpportunity opportunity;

  /// Cheapest landed price first.
  final List<OpportunityMarket> markets;

  /// Order size the landed prices assume (product's unit).
  final num referenceQuantity;

  @override
  List<Object?> get props => [opportunity, markets, referenceQuantity];
}

abstract interface class OpportunitiesRepository {
  /// Newest first.
  Future<Result<List<MarketOpportunity>>> getRecent();

  /// Also marks it read.
  Future<Result<OpportunityDetail>> getDetail(String id);
}
