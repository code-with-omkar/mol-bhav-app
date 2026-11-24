import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_products.dart';

/// What a unit measures (the API's `MeasureDimension`); fixed once the unit
/// exists.
enum UnitDimension {
  mass('Mass', 'kg'),
  volume('Volume', 'm³'),
  count('Count', 'piece'),
  length('Length', 'm'),
  area('Area', 'm²');

  const UnitDimension(this.wire, this.baseUnit);

  final String wire;

  /// What a unit's factor is counted in.
  final String baseUnit;

  static UnitDimension fromWire(String value) =>
      values.firstWhere((d) => d.wire == value, orElse: () => count);
}

/// Longest unit symbol the catalog accepts.
const unitSymbolMaxLength = 16;

/// A unit of measure, as the API's full-replacement update needs it.
class AdminUnit extends Equatable {
  const AdminUnit({
    required this.id,
    required this.code,
    required this.symbol,
    required this.dimension,
    required this.toBaseFactor,
    required this.isActive,
    required this.translations,
  });

  final String id;
  final String code;
  final String symbol;
  final UnitDimension dimension;

  /// How many of the dimension's base unit one of this unit is.
  final double toBaseFactor;
  final bool isActive;
  final List<ProductTranslation> translations;

  String nameIn(String language) =>
      translations.where((t) => t.language == language).firstOrNull?.name ?? '';

  /// English, falling back to the code.
  String get label {
    final en = nameIn('en');
    return en.isEmpty ? code : en;
  }

  /// With the editor's symbol, names and on/off applied.
  AdminUnit edited({
    required String symbol,
    required Map<String, String> names,
    required bool isActive,
  }) => AdminUnit(
    id: id,
    code: code,
    symbol: symbol.trim(),
    dimension: dimension,
    toBaseFactor: toBaseFactor,
    isActive: isActive,
    translations: translationsWithNames(translations, names),
  );

  @override
  List<Object?> get props => [
    id,
    code,
    symbol,
    dimension,
    toBaseFactor,
    isActive,
    translations,
  ];
}

/// A factor typed as text; null when it is not a positive number with at most
/// six decimals.
double? parseUnitFactor(String text) {
  final t = text.trim();
  if (!RegExp(r'^\d+(\.\d{1,6})?$').hasMatch(t)) return null;
  final v = double.parse(t);
  return v > 0 ? v : null;
}

enum UnitProblem {
  codeInvalid,
  symbolInvalid,
  englishMissing,
  tooLong,
  factorInvalid,
  dimensionMissing,
}

/// What is wrong with a unit being saved. The code and factor are only checked
/// for a new unit (they cannot be changed afterwards).
Set<UnitProblem> unitProblems({
  required bool isNew,
  required String code,
  required String symbol,
  required String factor,
  required Map<String, String> names,
}) => {
  if (isNew && !isValidProductCode(code)) UnitProblem.codeInvalid,
  if (symbol.trim().isEmpty || symbol.trim().length > unitSymbolMaxLength)
    UnitProblem.symbolInvalid,
  if ((names['en'] ?? '').trim().isEmpty) UnitProblem.englishMissing,
  if (names.values.any((n) => n.trim().length > productNameMaxLength))
    UnitProblem.tooLong,
  if (isNew && parseUnitFactor(factor) == null) UnitProblem.factorInvalid,
};

abstract interface class AdminUnitsRepository {
  /// Every unit (inactive too).
  Future<Result<List<AdminUnit>>> getUnits();

  Future<Result<void>> createUnit({
    required String code,
    required String symbol,
    required UnitDimension dimension,
    required double toBaseFactor,
    required Map<String, String> names,
  });

  /// Replaces the unit's symbol, names and on/off.
  Future<Result<void>> updateUnit(AdminUnit unit);
}
