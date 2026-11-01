import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Why a market was not added (the API's `FeedMarketSkipReason`).
enum FeedMarketSkipReason {
  notInFeed('NotInFeed'),
  alreadyInCatalog('AlreadyInCatalog'),
  codeInvalid('CodeInvalid'),
  districtUnknown('DistrictUnknown'),
  nameInvalid('NameInvalid');

  const FeedMarketSkipReason(this.wire);

  final String wire;

  /// A reason this build does not know reads as [nameInvalid], the generic one.
  static FeedMarketSkipReason fromWire(String value) =>
      values.firstWhere((r) => r.wire == value, orElse: () => nameInvalid);
}

class SkippedMarket extends Equatable {
  const SkippedMarket({required this.market, required this.reason});

  final String market;
  final FeedMarketSkipReason reason;

  @override
  List<Object?> get props => [market, reason];
}

/// What adding feed markets to the catalog did.
class ImportMarketsResult extends Equatable {
  const ImportMarketsResult({required this.created, required this.skipped});

  final int created;
  final List<SkippedMarket> skipped;

  @override
  List<Object?> get props => [created, skipped];
}

abstract interface class AdminMarketsRepository {
  /// Adds [markets] of [state] (spelled as in the feed list) to the catalog
  /// as mandis, for the price source [sourceId].
  Future<Result<ImportMarketsResult>> importFeedMarkets({
    required String sourceId,
    required String state,
    required List<String> markets,
  });
}
