import 'package:equatable/equatable.dart';

/// Everything the Home dashboard shows, in one response.
class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.userName,
    required this.hasUnreadAlerts,
    required this.categories,
    required this.topOpportunity,
    required this.watchlist,
  });

  final String userName;
  final bool hasUnreadAlerts;

  /// The user's selected procurement categories.
  final List<HomeCategory> categories;
  final TopOpportunity? topOpportunity;

  /// First few watchlist items.
  final List<WatchlistPreview> watchlist;

  @override
  List<Object?> get props => [
    userName,
    hasUnreadAlerts,
    categories,
    topOpportunity,
    watchlist,
  ];
}

class HomeCategory extends Equatable {
  const HomeCategory({
    required this.code,
    required this.name,
    required this.highlights,
  });

  final String code;
  final String name;
  final List<String> highlights;

  @override
  List<Object?> get props => [code, name, highlights];
}

class TopOpportunity extends Equatable {
  const TopOpportunity({
    required this.commodityId,
    required this.product,
    required this.categoryCode,
    required this.priceSource,
    required this.updatedAt,
    required this.price,
    required this.unit,
    required this.change,
    required this.percent,
    required this.trend,
    required this.bestMarketName,
  });

  final String commodityId;
  final String product;
  final String categoryCode;

  /// Where the headline price comes from, e.g. "Mandi Price (Pune)".
  final String priceSource;
  final DateTime updatedAt;
  final num price;
  final String unit;
  final num? change;
  final double? percent;
  final List<num> trend;
  final String? bestMarketName;

  @override
  List<Object?> get props => [
    commodityId,
    product,
    categoryCode,
    priceSource,
    updatedAt,
    price,
    unit,
    change,
    percent,
    trend,
    bestMarketName,
  ];
}

class WatchlistPreview extends Equatable {
  const WatchlistPreview({
    required this.commodityId,
    required this.marketId,
    required this.name,
    required this.categoryCode,
    required this.price,
    required this.unit,
    required this.percent,
  });

  final String commodityId;
  final String marketId;
  final String name;
  final String categoryCode;
  final num price;
  final String unit;
  final double? percent;

  @override
  List<Object?> get props => [
    commodityId,
    marketId,
    name,
    categoryCode,
    price,
    unit,
    percent,
  ];
}
