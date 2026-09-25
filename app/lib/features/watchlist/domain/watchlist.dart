import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

class Watchlist extends Equatable {
  const Watchlist({
    required this.categories,
    required this.items,
    required this.updatedAt,
  });

  /// Filter tabs: the categories present in the watchlist.
  final List<WatchlistCategory> categories;
  final List<WatchlistItem> items;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [categories, items, updatedAt];
}

class WatchlistCategory extends Equatable {
  const WatchlistCategory({required this.code, required this.name});

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

enum AlertCondition { below, above, percent }

class WatchlistItem extends Equatable {
  const WatchlistItem({
    required this.id,
    required this.commodityId,
    required this.marketId,
    required this.name,
    required this.categoryCode,
    required this.price,
    required this.unit,
    required this.percent,
    required this.trend,
    this.variety,
    this.marketName,
    this.alertCondition,
    this.alertValue,
  });

  final String id;
  final String commodityId;
  final String marketId;
  final String name;
  final String categoryCode;
  final num price;
  final String unit;
  final double? percent;
  final List<num> trend;

  /// Grade or variety, e.g. "Fe 500D".
  final String? variety;
  final String? marketName;
  final AlertCondition? alertCondition;
  final num? alertValue;

  @override
  List<Object?> get props => [
    id,
    commodityId,
    marketId,
    name,
    categoryCode,
    price,
    unit,
    percent,
    trend,
    variety,
    marketName,
    alertCondition,
    alertValue,
  ];
}

abstract interface class WatchlistRepository {
  Future<Result<Watchlist>> getWatchlist();
}

@injectable
class GetWatchlist {
  const GetWatchlist(this._repository);

  final WatchlistRepository _repository;

  Future<Result<Watchlist>> call() => _repository.getWatchlist();
}
