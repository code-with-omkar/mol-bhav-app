import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import 'markets_entities.dart';

abstract interface class MarketsRepository {
  Future<Result<List<Commodity>>> getCommodities();

  /// Cached comparison first, then the live one. [marketIds] `null` lets
  /// the API choose the user's default markets.
  Stream<Result<MarketComparison>> watchComparison(
    String commodityId, {
    List<String>? marketIds,
  });

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
    List<String>? marketIds,
  }) => _repository.watchComparison(commodityId, marketIds: marketIds);
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
