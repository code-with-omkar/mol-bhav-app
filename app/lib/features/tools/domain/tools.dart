import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../core/error/failure.dart';
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
    required this.unit,
  });

  final String id;
  final String name;
  final String categoryCode;

  /// The product's default unit. The API prices requirements only in it, so
  /// the unit picker is locked to it.
  final NamedOption unit;

  @override
  List<Object?> get props => [id, name, categoryCode, unit];
}

class EstimateRequest extends Equatable {
  const EstimateRequest({
    required this.materialId,
    required this.quantity,
    required this.unitId,
    this.districtId,
  });

  final String materialId;
  final num quantity;
  final String unitId;

  /// Delivery district; `null` compares every location with prices.
  final String? districtId;

  @override
  List<Object?> get props => [materialId, quantity, unitId, districtId];
}

/// A priced requirement: the saved (or about-to-be-saved) estimate.
class Estimate extends Equatable {
  const Estimate({
    required this.requirementId,
    required this.estimatedCost,
    required this.quantity,
    required this.lowestPrice,
    required this.lowestSourceName,
    required this.averagePrice,
    required this.savings,
    required this.benchmarks,
    required this.updatedAt,
  });

  final String requirementId;

  /// Cheapest location's total, including the platform's cost components.
  final num estimatedCost;
  final num quantity;
  final num lowestPrice;
  final String lowestSourceName;

  /// Mean unit price across the compared locations: the reference.
  final num averagePrice;

  /// What buying at the cheapest location saves against [averagePrice].
  final num savings;
  final List<Benchmark> benchmarks;

  /// Date of the price the cheapest option is based on (data freshness).
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    requirementId,
    estimatedCost,
    quantity,
    lowestPrice,
    lowestSourceName,
    averagePrice,
    savings,
    benchmarks,
    updatedAt,
  ];
}

class Benchmark extends Equatable {
  const Benchmark({
    required this.name,
    required this.price,
    required this.isLowest,
    required this.recordDate,
  });

  final String name;
  final num price;
  final bool isLowest;

  /// Date of the price this location is compared on.
  final DateTime recordDate;

  @override
  List<Object?> get props => [name, price, isLowest, recordDate];
}

class SavedEstimate extends Equatable {
  const SavedEstimate({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitSymbol,
    required this.districtName,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final num quantity;
  final String unitSymbol;
  final String? districtName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    unitSymbol,
    districtName,
    createdAt,
  ];
}

/// No location has a recent price for the product.
final class NoPricesFailure extends Failure {
  const NoPricesFailure();
}

abstract interface class EstimatorRepository {
  /// Creates a requirement and prices it (`POST /procurement/requirements`,
  /// then `POST …/{id}/opportunities`).
  Future<Result<Estimate>> estimate(EstimateRequest request);

  /// Re-prices a saved requirement.
  Future<Result<Estimate>> reprice(SavedEstimate saved);

  Future<Result<List<SavedEstimate>>> getSaved();

  Future<Result<void>> delete(String requirementId);
}

// --- Reports ---------------------------------------------------------------

enum ReportKind { weeklySummary, priceHistoryCsv }

enum ReportStatus { pending, ready, failed }

class ReportRequest extends Equatable {
  const ReportRequest({
    required this.kind,
    required this.from,
    required this.to,
    required this.language,
    this.productId,
    this.mandiId,
  });

  final ReportKind kind;
  final DateTime from;
  final DateTime to;
  final String language;

  /// Price history CSV only.
  final String? productId;
  final String? mandiId;

  @override
  List<Object?> get props => [kind, from, to, language, productId, mandiId];
}

class GeneratedReport extends Equatable {
  const GeneratedReport({
    required this.id,
    required this.kind,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    this.lastDownloadedAt,
    this.failureReason,
  });

  final String id;

  /// `null` for report types this app version doesn't request.
  final ReportKind? kind;
  final ReportStatus status;
  final DateTime requestedAt;

  /// When generation finished — null while still pending.
  final DateTime? completedAt;

  /// When this device's user last downloaded the file — null until they do.
  final DateTime? lastDownloadedAt;
  final String? failureReason;

  @override
  List<Object?> get props => [
    id,
    kind,
    status,
    requestedAt,
    completedAt,
    lastDownloadedAt,
    failureReason,
  ];
}

class DownloadedFile {
  const DownloadedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

abstract interface class ReportsRepository {
  Future<Result<List<GeneratedReport>>> getReports();

  /// Returns the new report's id.
  Future<Result<String>> request(ReportRequest request);

  Future<Result<GeneratedReport>> getReport(String id);

  Future<Result<DownloadedFile>> download(String id);
}
