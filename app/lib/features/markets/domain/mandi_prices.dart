import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

/// A state, district or mandi in the browse-by-mandi pickers.
class LocationOption extends Equatable {
  const LocationOption({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Latest price of one product/variant at a mandi.
class MandiPrice extends Equatable {
  const MandiPrice({
    required this.productId,
    required this.productName,
    this.variantId,
    required this.variantName,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.unitSymbol,
    required this.recordDate,
    required this.source,
  });

  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final num modalPrice;
  final num? minPrice;
  final num? maxPrice;
  final String unitSymbol;
  final DateTime recordDate;
  final String source;

  @override
  List<Object?> get props => [
    productId,
    productName,
    variantId,
    variantName,
    modalPrice,
    minPrice,
    maxPrice,
    unitSymbol,
    recordDate,
    source,
  ];
}

abstract interface class MandiPricesRepository {
  Future<Result<List<LocationOption>>> getStates();

  Future<Result<List<LocationOption>>> getDistricts(String stateId);

  Future<Result<List<LocationOption>>> getMandis(String districtId);

  Future<Result<List<MandiPrice>>> getPrices(String mandiId);
}

@injectable
class GetMandiPrices {
  const GetMandiPrices(this._repository);

  final MandiPricesRepository _repository;

  Future<Result<List<LocationOption>>> states() => _repository.getStates();

  Future<Result<List<LocationOption>>> districts(String stateId) =>
      _repository.getDistricts(stateId);

  Future<Result<List<LocationOption>>> mandis(String districtId) =>
      _repository.getMandis(districtId);

  Future<Result<List<MandiPrice>>> prices(String mandiId) =>
      _repository.getPrices(mandiId);
}
