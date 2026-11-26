import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import 'markets_entities.dart';

abstract interface class MarketsRepository {
  Future<Result<List<Commodity>>> getCommodities();

  /// Cached comparison first, then the live one, for the markets of [stateId]
  /// (`null`: the cheapest across all states). [marketIds] `null` selects
  /// every market returned.
  Stream<Result<MarketComparison>> watchComparison(
    String commodityId, {
    String? stateId,
    List<String>? marketIds,
  });

  /// The state a market is in, when it has a price for the product.
  Future<Result<String?>> getMarketStateName(
    String commodityId,
    String marketId,
  );

  Future<Result<PriceTrend>> getTrend(
    String commodityId,
    String marketId,
    TrendRange range,
  );

  Future<Result<BuyingOpportunity>> getOpportunity(String id);
}

@injectable
class GetCommodities {
  const GetCommodities(this._repository);

  final MarketsRepository _repository;

  Future<Result<List<Commodity>>> call() => _repository.getCommodities();
}

@injectable
class GetMarketComparison {
  const GetMarketComparison(this._repository);

  final MarketsRepository _repository;

  Stream<Result<MarketComparison>> call(
    String commodityId, {
    String? stateId,
    List<String>? marketIds,
  }) => _repository.watchComparison(
    commodityId,
    stateId: stateId,
    marketIds: marketIds,
  );

  Future<Result<String?>> stateOf(String commodityId, String marketId) =>
      _repository.getMarketStateName(commodityId, marketId);
}

@injectable
class GetPriceTrend {
  const GetPriceTrend(this._repository);

  final MarketsRepository _repository;

  Future<Result<PriceTrend>> call(
    String commodityId,
    String marketId,
    TrendRange range,
  ) => _repository.getTrend(commodityId, marketId, range);
}

@injectable
class GetBuyingOpportunity {
  const GetBuyingOpportunity(this._repository);

  final MarketsRepository _repository;

  Future<Result<BuyingOpportunity>> call(String id) =>
      _repository.getOpportunity(id);
}
