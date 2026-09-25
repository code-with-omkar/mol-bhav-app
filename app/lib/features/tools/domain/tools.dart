import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

class NamedOption extends Equatable {
  const NamedOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class EstimatorMaterial extends Equatable {
  const EstimatorMaterial({
    required this.id,
    required this.name,
    required this.categoryCode,
    required this.units,
  });

  final String id;
  final String name;
  final String categoryCode;

  /// Units the material can be ordered in, e.g. Bags, Tonnes.
  final List<NamedOption> units;

  @override
  List<Object?> get props => [id, name, categoryCode, units];
}

class EstimatorOptions extends Equatable {
  const EstimatorOptions({
    required this.categories,
    required this.materials,
    required this.locations,
  });

  /// `id` is the category code.
  final List<NamedOption> categories;
  final List<EstimatorMaterial> materials;
  final List<NamedOption> locations;

  @override
  List<Object?> get props => [categories, materials, locations];
}

class EstimateRequest extends Equatable {
  const EstimateRequest({
    required this.materialId,
    required this.quantity,
    required this.unitId,
    required this.locationId,
  });

  final String materialId;
  final num quantity;
  final String unitId;
  final String locationId;

  @override
  List<Object?> get props => [materialId, quantity, unitId, locationId];
}

class Estimate extends Equatable {
  const Estimate({
    required this.estimatedCost,
    required this.quantity,
    required this.unitName,
    required this.priceUnit,
    required this.lowestPrice,
    required this.lowestSourceName,
    required this.averagePrice,
    required this.savings,
    required this.benchmarks,
    required this.source,
    required this.updatedAt,
  });

  final num estimatedCost;
  final num quantity;

  /// Quantity unit as entered, e.g. "bags".
  final String unitName;

  /// Benchmark price unit, e.g. "bag".
  final String priceUnit;
  final num lowestPrice;
  final String lowestSourceName;
  final num averagePrice;
  final num savings;
  final List<Benchmark> benchmarks;
  final String source;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    estimatedCost,
    quantity,
    unitName,
    priceUnit,
    lowestPrice,
    lowestSourceName,
    averagePrice,
    savings,
    benchmarks,
    source,
    updatedAt,
  ];
}

class Benchmark extends Equatable {
  const Benchmark({
    required this.name,
    required this.price,
    required this.isLowest,
    this.meta,
  });

  final String name;
  final String? meta;
  final num price;
  final bool isLowest;

  @override
  List<Object?> get props => [name, meta, price, isLowest];
}

class ReportsOverview extends Equatable {
  const ReportsOverview({
    required this.currentWeek,
    required this.weekly,
    required this.exports,
  });

  final WeekSummary? currentWeek;
  final List<WeeklyReport> weekly;
  final List<ExportItem> exports;

  bool get isEmpty => currentWeek == null && weekly.isEmpty && exports.isEmpty;

  @override
  List<Object?> get props => [currentWeek, weekly, exports];
}

class WeekSummary extends Equatable {
  const WeekSummary({
    required this.start,
    required this.end,
    required this.potentialSavings,
    required this.watchlistCount,
    required this.alertCount,
    required this.opportunityCount,
    required this.language,
  });

  final DateTime start;
  final DateTime end;
  final num potentialSavings;
  final int watchlistCount;
  final int alertCount;
  final int opportunityCount;

  /// Language code of the PDF.
  final String language;

  @override
  List<Object?> get props => [
    start,
    end,
    potentialSavings,
    watchlistCount,
    alertCount,
    opportunityCount,
    language,
  ];
}

class WeeklyReport extends Equatable {
  const WeeklyReport({
    required this.id,
    required this.start,
    required this.end,
    required this.language,
    required this.pages,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String language;
  final int pages;

  @override
  List<Object?> get props => [id, start, end, language, pages];
}

class ExportItem extends Equatable {
  const ExportItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isLocked,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// Pro-only for the current plan.
  final bool isLocked;

  @override
  List<Object?> get props => [id, title, subtitle, isLocked];
}

abstract interface class ToolsRepository {
  Future<Result<EstimatorOptions>> getEstimatorOptions();

  Future<Result<Estimate>> estimate(EstimateRequest request);

  Future<Result<void>> saveEstimate(EstimateRequest request);

  Future<Result<ReportsOverview>> getReports();
}

@injectable
class GetEstimatorOptions {
  const GetEstimatorOptions(this._repository);

  final ToolsRepository _repository;

  Future<Result<EstimatorOptions>> call() => _repository.getEstimatorOptions();
}

@injectable
class CalculateEstimate {
  const CalculateEstimate(this._repository);

  final ToolsRepository _repository;

  Future<Result<Estimate>> call(EstimateRequest request) =>
      _repository.estimate(request);
}

@injectable
class SaveEstimate {
  const SaveEstimate(this._repository);

  final ToolsRepository _repository;

  Future<Result<void>> call(EstimateRequest request) =>
      _repository.saveEstimate(request);
}

@injectable
class GetReports {
  const GetReports(this._repository);

  final ToolsRepository _repository;

  Future<Result<ReportsOverview>> call() => _repository.getReports();
}
