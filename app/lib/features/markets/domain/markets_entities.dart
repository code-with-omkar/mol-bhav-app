import 'package:equatable/equatable.dart';

class Commodity extends Equatable {
  const Commodity({
    required this.id,
    required this.name,
    required this.categoryCode,
  });

  final String id;
  final String name;
  final String categoryCode;

  @override
  List<Object?> get props => [id, name, categoryCode];
}

class MarketRef extends Equatable {
  const MarketRef({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// One commodity's price across nearby markets.
class MarketComparison extends Equatable {
  const MarketComparison({
    required this.commodityId,
    required this.categoryCode,
    required this.unit,
    required this.availableMarkets,
    required this.selectedMarketIds,
    required this.rows,
    required this.bestMarketId,
    required this.homeMarketId,
    required this.source,
    required this.updatedAt,
  });

  final String commodityId;
  final String categoryCode;

  /// Price unit, e.g. "Quintal".
  final String unit;
  final List<MarketRef> availableMarkets;
  final List<String> selectedMarketIds;
  final List<MarketPrice> rows;
  final String? bestMarketId;

  /// The user's own market, compared against the best one.
  final String? homeMarketId;
  final String source;
  final DateTime updatedAt;

  MarketPrice? rowFor(String? marketId) =>
      rows.where((r) => r.marketId == marketId).firstOrNull;

  @override
  List<Object?> get props => [
    commodityId,
    categoryCode,
    unit,
    availableMarkets,
    selectedMarketIds,
    rows,
    bestMarketId,
    homeMarketId,
    source,
    updatedAt,
  ];
}

class MarketPrice extends Equatable {
  const MarketPrice({
    required this.marketId,
    required this.marketName,
    required this.price,
    this.change,
    this.arrivals,
  });

  final String marketId;
  final String marketName;
  final num price;

  /// Day-on-day change in rupees.
  final num? change;

  /// Pre-formatted arrivals, e.g. "1,240 q".
  final String? arrivals;

  @override
  List<Object?> get props => [marketId, marketName, price, change, arrivals];
}

enum TrendRange {
  week('7D'),
  month('30D'),
  quarter('90D'),
  year('1Y');

  const TrendRange(this.code);

  /// API value and tab label.
  final String code;
}

class PriceTrend extends Equatable {
  const PriceTrend({
    required this.commodityName,
    required this.marketName,
    required this.unit,
    required this.points,
    required this.min,
    required this.modal,
    required this.max,
    required this.related,
  });

  final String commodityName;
  final String marketName;
  final String unit;
  final List<TrendSample> points;
  final num min;
  final num modal;
  final num max;
  final List<RelatedMarketPrice> related;

  @override
  List<Object?> get props => [
    commodityName,
    marketName,
    unit,
    points,
    min,
    modal,
    max,
    related,
  ];
}

class TrendSample extends Equatable {
  const TrendSample({required this.date, required this.value});

  final DateTime date;
  final num value;

  @override
  List<Object?> get props => [date, value];
}

class RelatedMarketPrice extends Equatable {
  const RelatedMarketPrice({
    required this.marketId,
    required this.marketName,
    required this.price,
    required this.unit,
    required this.percent,
  });

  final String marketId;
  final String marketName;
  final num price;
  final String unit;
  final double? percent;

  @override
  List<Object?> get props => [marketId, marketName, price, unit, percent];
}

/// Where to buy a required quantity, with the saving versus the user's
/// reference market.
class BuyingOpportunity extends Equatable {
  const BuyingOpportunity({
    required this.id,
    required this.commodityName,
    required this.categoryCode,
    required this.quantity,
    required this.quantityUnit,
    required this.deliverTo,
    required this.priceUnit,
    required this.markets,
    required this.bestMarketId,
    required this.referenceMarketId,
    required this.potentialDifference,
    required this.source,
    required this.updatedAt,
  });

  final String id;
  final String commodityName;
  final String categoryCode;
  final num quantity;
  final String quantityUnit;
  final String deliverTo;
  final String priceUnit;
  final List<MarketRefPrice> markets;
  final String bestMarketId;
  final String referenceMarketId;
  final num potentialDifference;
  final String source;
  final DateTime updatedAt;

  MarketRefPrice? get best =>
      markets.where((m) => m.marketId == bestMarketId).firstOrNull;
  MarketRefPrice? get reference =>
      markets.where((m) => m.marketId == referenceMarketId).firstOrNull;

  @override
  List<Object?> get props => [
    id,
    commodityName,
    categoryCode,
    quantity,
    quantityUnit,
    deliverTo,
    priceUnit,
    markets,
    bestMarketId,
    referenceMarketId,
    potentialDifference,
    source,
    updatedAt,
  ];
}

class MarketRefPrice extends Equatable {
  const MarketRefPrice({
    required this.marketId,
    required this.marketName,
    required this.price,
  });

  final String marketId;
  final String marketName;
  final num price;

  @override
  List<Object?> get props => [marketId, marketName, price];
}
