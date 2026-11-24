import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_products.dart';

/// A sub-category, as the API's full-replacement update needs it.
class AdminSubCategory extends Equatable {
  const AdminSubCategory({
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
  AdminSubCategory edited({
    required Map<String, String> names,
    required bool isActive,
  }) => AdminSubCategory(
    id: id,
    code: code,
    displayOrder: displayOrder,
    isActive: isActive,
    translations: translationsWithNames(translations, names),
  );

  @override
  List<Object?> get props => [id, code, displayOrder, isActive, translations];
}

/// A category with its sub-categories, as the API's full-replacement update
/// needs it.
class AdminCategory extends Equatable {
  const AdminCategory({
    required this.id,
    required this.code,
    required this.displayOrder,
    required this.isActive,
    required this.translations,
    this.iconKey,
    this.subCategories = const [],
  });

  final String id;
  final String code;
  final String? iconKey;
  final int displayOrder;
  final bool isActive;
  final List<ProductTranslation> translations;
  final List<AdminSubCategory> subCategories;

  String nameIn(String language) =>
      translations.where((t) => t.language == language).firstOrNull?.name ?? '';

  /// English, falling back to the code.
  String get label {
    final en = nameIn('en');
    return en.isEmpty ? code : en;
  }

  /// With the editor's names and on/off applied (see [translationsWithNames]).
  AdminCategory edited({
    required Map<String, String> names,
    required bool isActive,
  }) => AdminCategory(
    id: id,
    code: code,
    iconKey: iconKey,
    displayOrder: displayOrder,
    isActive: isActive,
    translations: translationsWithNames(translations, names),
    subCategories: subCategories,
  );

  @override
  List<Object?> get props => [
    id,
    code,
    iconKey,
    displayOrder,
    isActive,
    translations,
    subCategories,
  ];
}

/// What is wrong with the code and names being saved. The code is only checked
/// for a new item (it cannot be changed afterwards).
enum CategoryProblem { codeInvalid, englishMissing, tooLong }

Set<CategoryProblem> categoryProblems({
  required bool isNew,
  required String code,
  required Map<String, String> names,
}) => {
  if (isNew && !isValidProductCode(code)) CategoryProblem.codeInvalid,
  if ((names['en'] ?? '').trim().isEmpty) CategoryProblem.englishMissing,
  if (names.values.any((n) => n.trim().length > productNameMaxLength))
    CategoryProblem.tooLong,
};

abstract interface class AdminCategoriesRepository {
  /// Every category (inactive too) with its sub-categories.
  Future<Result<List<AdminCategory>>> getCategories();

  Future<Result<void>> createCategory({
    required String code,
    required Map<String, String> names,
  });

  /// Replaces the category's names and on/off (its sub-categories are managed
  /// separately).
  Future<Result<void>> updateCategory(AdminCategory category);

  Future<Result<void>> addSubCategory({
    required String categoryId,
    required String code,
    required Map<String, String> names,
  });

  Future<Result<void>> updateSubCategory({
    required String categoryId,
    required AdminSubCategory subCategory,
  });
}
