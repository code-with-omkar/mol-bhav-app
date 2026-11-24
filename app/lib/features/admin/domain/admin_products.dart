import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Languages the product editor offers (the catalog supports more, which are
/// kept as they are).
const productNameLanguages = ['en', 'hi', 'mr'];

/// Longest product name the catalog accepts.
const productNameMaxLength = 120;

/// A product in the admin list.
class AdminProductSummary extends Equatable {
  const AdminProductSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryCode,
    required this.subCategoryCode,
    required this.unitCode,
    required this.isActive,
  });

  final String id;
  final String code;

  /// The English name.
  final String name;
  final String categoryCode;
  final String subCategoryCode;
  final String unitCode;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    categoryCode,
    subCategoryCode,
    unitCode,
    isActive,
  ];
}

class ProductTranslation extends Equatable {
  const ProductTranslation({
    required this.language,
    required this.name,
    this.description,
  });

  final String language;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [language, name, description];
}

/// [translations] with the editor's [names] applied: a changed name replaces
/// that language's, a blank one removes it, and languages not in [names] and
/// every description are kept.
List<ProductTranslation> translationsWithNames(
  List<ProductTranslation> translations,
  Map<String, String> names,
) {
  final updated = <ProductTranslation>[];
  for (final t in translations) {
    if (!names.containsKey(t.language)) {
      updated.add(t);
      continue;
    }
    final name = names[t.language]!.trim();
    if (name.isNotEmpty) {
      updated.add(
        ProductTranslation(
          language: t.language,
          name: name,
          description: t.description,
        ),
      );
    }
  }
  for (final entry in names.entries) {
    final name = entry.value.trim();
    if (name.isNotEmpty && !updated.any((t) => t.language == entry.key)) {
      updated.add(ProductTranslation(language: entry.key, name: name));
    }
  }
  return updated;
}

/// A whole product, as the API's full-replacement update needs it.
class AdminProduct extends Equatable {
  const AdminProduct({
    required this.id,
    required this.code,
    required this.subCategoryId,
    required this.defaultUnitId,
    required this.displayOrder,
    required this.isActive,
    required this.translations,
    this.imageKey,
    this.variants = const [],
  });

  final String id;
  final String code;
  final String subCategoryId;
  final String defaultUnitId;
  final int displayOrder;
  final bool isActive;
  final String? imageKey;
  final List<ProductTranslation> translations;

  /// Grades or forms of the product (for example "Large"); managed one by one,
  /// not part of the product's own update.
  final List<AdminVariant> variants;

  /// The name in [language], or empty when there is none.
  String nameIn(String language) =>
      translations.where((t) => t.language == language).firstOrNull?.name ?? '';

  /// This product with the editor's names and on/off applied. A blank Hindi or
  /// Marathi name removes that translation; English cannot be blank. Other
  /// languages and every description are kept.
  AdminProduct edited({
    required Map<String, String> names,
    required bool isActive,
  }) {
    final updated = translationsWithNames(translations, names);
    return AdminProduct(
      id: id,
      code: code,
      subCategoryId: subCategoryId,
      defaultUnitId: defaultUnitId,
      displayOrder: displayOrder,
      isActive: isActive,
      imageKey: imageKey,
      translations: updated,
      variants: variants,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    subCategoryId,
    defaultUnitId,
    displayOrder,
    isActive,
    imageKey,
    translations,
    variants,
  ];
}

/// A product variant, as the API's full-replacement update needs it.
class AdminVariant extends Equatable {
  const AdminVariant({
    required this.id,
    required this.code,
    required this.displayOrder,
    required this.isActive,
    required this.translations,
  });

  final String id;
  final String code;
  final int displayOrder;
  final bool isActive;
  final List<ProductTranslation> translations;

  String nameIn(String language) =>
      translations.where((t) => t.language == language).firstOrNull?.name ?? '';

  /// English, falling back to the code.
  String get label {
    final en = nameIn('en');
    return en.isEmpty ? code : en;
  }

  /// With the editor's names and on/off applied (see [translationsWithNames]).
  AdminVariant edited({
    required Map<String, String> names,
    required bool isActive,
  }) => AdminVariant(
    id: id,
    code: code,
    displayOrder: displayOrder,
    isActive: isActive,
    translations: translationsWithNames(translations, names),
  );

  @override
  List<Object?> get props => [id, code, displayOrder, isActive, translations];
}

/// What is wrong with the names being edited.
enum ProductNameProblem { englishMissing, tooLong }

Set<ProductNameProblem> productNameProblems(Map<String, String> names) => {
  if ((names['en'] ?? '').trim().isEmpty) ProductNameProblem.englishMissing,
  if (names.values.any((n) => n.trim().length > productNameMaxLength))
    ProductNameProblem.tooLong,
};

abstract interface class AdminProductsRepository {
  /// One page of products (inactive ones too), filtered by [search].
  Future<Result<List<AdminProductSummary>>> getProducts({
    required int page,
    required int pageSize,
    String? search,
  });

  Future<Result<AdminProduct>> getProduct(String id);

  /// Replaces the product with [product].
  Future<Result<void>> updateProduct(AdminProduct product);

  Future<Result<void>> addVariant({
    required String productId,
    required String code,
    required Map<String, String> names,
  });

  Future<Result<void>> updateVariant({
    required String productId,
    required AdminVariant variant,
  });

  /// Adds a product; [names] maps a language to its name (blank ones are left
  /// out).
  Future<Result<void>> createProduct({
    required String code,
    required String subCategoryId,
    required String unitId,
    required Map<String, String> names,
  });
}

/// A catalog code: lowercase, starts with a letter, then letters, digits or
/// hyphens, 40 characters at most.
final _productCode = RegExp(r'^[a-z][a-z0-9-]{0,39}$');

bool isValidProductCode(String code) => _productCode.hasMatch(code.trim());

/// What is wrong with a new product.
enum NewProductProblem {
  codeInvalid,
  englishMissing,
  subCategoryMissing,
  unitMissing,
}

Set<NewProductProblem> newProductProblems({
  required String code,
  required Map<String, String> names,
  required String? subCategoryId,
  required String? unitId,
}) => {
  if (!isValidProductCode(code)) NewProductProblem.codeInvalid,
  if ((names['en'] ?? '').trim().isEmpty) NewProductProblem.englishMissing,
  if (subCategoryId == null) NewProductProblem.subCategoryMissing,
  if (unitId == null) NewProductProblem.unitMissing,
};
