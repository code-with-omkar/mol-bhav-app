import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_products.dart';

/// Longest mandi name the API accepts.
const mandiNameMaxLength = 150;

/// A mandi (market) in the admin list.
class AdminMandi extends Equatable {
  const AdminMandi({
    required this.id,
    required this.code,
    required this.name,
    required this.districtId,
    required this.districtName,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String districtId;
  final String districtName;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    districtId,
    districtName,
    isActive,
  ];
}

/// A district a mandi can sit in, labelled "State › District".
class DistrictChoice extends Equatable {
  const DistrictChoice({required this.id, required this.label});

  final String id;
  final String label;

  @override
  List<Object?> get props => [id, label];
}

enum MandiProblem { codeInvalid, nameMissing, nameTooLong, districtMissing }

/// What is wrong with a mandi being saved. The code is only checked for a new
/// mandi (it cannot be changed afterwards).
Set<MandiProblem> mandiProblems({
  required bool isNew,
  required String code,
  required String name,
  required String? districtId,
}) => {
  if (isNew && !isValidProductCode(code)) MandiProblem.codeInvalid,
  if (name.trim().isEmpty) MandiProblem.nameMissing,
  if (name.trim().length > mandiNameMaxLength) MandiProblem.nameTooLong,
  if (districtId == null) MandiProblem.districtMissing,
};

abstract interface class AdminMandisRepository {
  /// One page of mandis (inactive too), filtered by [search].
  Future<Result<List<AdminMandi>>> getMandis({
    required int page,
    required int pageSize,
    String? search,
  });

  /// Every active district, labelled with its state.
  Future<Result<List<DistrictChoice>>> getDistricts();

  Future<Result<void>> createMandi({
    required String code,
    required String name,
    required String districtId,
  });

  /// Replaces the mandi's name, district and on/off.
  Future<Result<void>> updateMandi({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
  });
}
