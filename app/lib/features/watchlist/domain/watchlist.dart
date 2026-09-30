import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
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
    this.variantId,
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

  /// The watched product.
  final String commodityId;

  /// Set when a single variant is watched instead of the whole product.
  final String? variantId;
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
    variantId,
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

/// The item is on the watchlist already (API 409).
final class AlreadyWatchedFailure extends Failure {
  const AlreadyWatchedFailure();
}

abstract interface class WatchlistRepository {
  /// Cached watchlist first, then the live one.
  Stream<Result<Watchlist>> watchWatchlist();

  /// Fails with [AlreadyWatchedFailure] for a duplicate.
  Future<Result<void>> add(String productId, {String? variantId});

  Future<Result<void>> remove(String itemId);
}

@injectable
class WatchWatchlist {
  const WatchWatchlist(this._repository);

  final WatchlistRepository _repository;

  Stream<Result<Watchlist>> call() => _repository.watchWatchlist();
}

@injectable
class AddToWatchlist {
  const AddToWatchlist(this._repository);

  final WatchlistRepository _repository;

  Future<Result<void>> call(String productId, {String? variantId}) =>
      _repository.add(productId, variantId: variantId);
}

@injectable
class RemoveFromWatchlist {
  const RemoveFromWatchlist(this._repository);

  final WatchlistRepository _repository;

  Future<Result<void>> call(String itemId) => _repository.remove(itemId);
}
