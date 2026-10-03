import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

class CatalogCategory extends Equatable {
  const CatalogCategory({required this.code, required this.name});

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// The categories the user registered for, in catalog order.
///
/// Every category picker (watchlist, comparison, estimator) goes through this
/// so a user who buys only agri produce never sees a Construction tab. Falls
/// back to [all] when the profile names no category, or none of them is in
/// the catalog any more, so a picker is never left empty.
List<CatalogCategory> userCategories(
  List<CatalogCategory> all,
  Iterable<String> userCategoryCodes,
) {
  final codes = userCategoryCodes.toSet();
  if (codes.isEmpty) return all;
  final mine = [
    for (final c in all)
      if (codes.contains(c.code)) c,
  ];
  return mine.isEmpty ? all : mine;
}

class CatalogUnit extends Equatable {
  const CatalogUnit({
    required this.id,
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String id;
  final String code;
  final String symbol;
  final String name;

  @override
  List<Object?> get props => [id, code, symbol, name];
}

class CatalogProduct extends Equatable {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.subCategoryName,
    required this.defaultUnit,
  });

  final String id;
  final String name;
  final String subCategoryName;

  /// Prices and procurement quantities are expressed in this unit.
  final CatalogUnit defaultUnit;

  @override
  List<Object?> get props => [id, name, subCategoryName, defaultUnit];
}

class CatalogVariant extends Equatable {
  const CatalogVariant({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class CatalogProductDetail extends Equatable {
  const CatalogProductDetail({required this.product, required this.variants});

  final CatalogProduct product;
  final List<CatalogVariant> variants;

  @override
  List<Object?> get props => [product, variants];
}

/// Read-only catalog lookups for pickers. Names come localised.
abstract interface class CatalogRepository {
  Future<Result<List<CatalogCategory>>> getCategories();

  /// Products of [categoryCode] whose name matches [search] (all when empty).
  Future<Result<List<CatalogProduct>>> getProducts(
    String categoryCode, {
    String search = '',
  });

  Future<Result<CatalogProductDetail>> getProduct(String id);
}
