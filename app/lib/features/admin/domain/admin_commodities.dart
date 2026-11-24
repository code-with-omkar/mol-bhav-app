import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Why a commodity was not added (the API's `FeedCommoditySkipReason`).
enum FeedCommoditySkipReason {
  notInFeed('NotInFeed'),
  alreadyInCatalog('AlreadyInCatalog'),
  codeInvalid('CodeInvalid'),
  nameInvalid('NameInvalid');

  const FeedCommoditySkipReason(this.wire);

  final String wire;

  /// A reason this build does not know reads as [nameInvalid], the generic one.
  static FeedCommoditySkipReason fromWire(String value) =>
      values.firstWhere((r) => r.wire == value, orElse: () => nameInvalid);
}

class SkippedCommodity extends Equatable {
  const SkippedCommodity({required this.commodity, required this.reason});

  final String commodity;
  final FeedCommoditySkipReason reason;

  @override
  List<Object?> get props => [commodity, reason];
}

/// What adding feed commodities to the catalog did.
class ImportCommoditiesResult extends Equatable {
  const ImportCommoditiesResult({required this.created, required this.skipped});

  final int created;
  final List<SkippedCommodity> skipped;

  @override
  List<Object?> get props => [created, skipped];
}

/// A sub-category or unit the new products can be filed under.
class CatalogChoice extends Equatable {
  const CatalogChoice({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

/// Where new products can go: every sub-category (labelled
/// "Category › Sub-category") and every unit.
class CommodityTargets extends Equatable {
  const CommodityTargets({
    this.subCategories = const [],
    this.units = const [],
  });

  final List<CatalogChoice> subCategories;
  final List<CatalogChoice> units;

  @override
  List<Object?> get props => [subCategories, units];
}

abstract interface class AdminCommoditiesRepository {
  /// The active sub-categories and units a new product can use.
  Future<Result<CommodityTargets>> getTargets();

  /// Adds [commodities] (spelled as in the feed list) to the catalog as
  /// products under [subCategoryId], priced in [unitId].
  Future<Result<ImportCommoditiesResult>> importFeedProducts({
    required String sourceId,
    required String subCategoryId,
    required String unitId,
    required List<String> commodities,
  });
}
