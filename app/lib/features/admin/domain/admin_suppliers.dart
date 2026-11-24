import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_mandis.dart';
import 'admin_products.dart';

/// Longest contact phone number the API accepts.
const supplierPhoneMaxLength = 20;

/// A supplier or hub in the admin list.
class AdminSupplier extends Equatable {
  const AdminSupplier({
    required this.id,
    required this.code,
    required this.name,
    required this.districtId,
    required this.districtName,
    required this.isActive,
    this.contactPhone,
  });

  final String id;
  final String code;
  final String name;
  final String districtId;
  final String districtName;
  final String? contactPhone;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    districtId,
    districtName,
    contactPhone,
    isActive,
  ];
}

enum SupplierProblem {
  codeInvalid,
  nameMissing,
  nameTooLong,
  districtMissing,
  phoneInvalid,
}

/// What is wrong with a supplier being saved. The code is only checked for a
/// new supplier (it cannot be changed afterwards). The phone is optional: digits
/// with an optional leading + and spaces or hyphens.
Set<SupplierProblem> supplierProblems({
  required bool isNew,
  required String code,
  required String name,
  required String? districtId,
  String phone = '',
}) => {
  if (isNew && !isValidProductCode(code)) SupplierProblem.codeInvalid,
  if (name.trim().isEmpty) SupplierProblem.nameMissing,
  if (name.trim().length > mandiNameMaxLength) SupplierProblem.nameTooLong,
  if (districtId == null) SupplierProblem.districtMissing,
  if (phone.trim().isNotEmpty && !isValidSupplierPhone(phone))
    SupplierProblem.phoneInvalid,
};

final _phone = RegExp(r'^\+?[0-9][0-9 \-]{4,18}$');

bool isValidSupplierPhone(String phone) =>
    phone.trim().length <= supplierPhoneMaxLength &&
    _phone.hasMatch(phone.trim());

abstract interface class AdminSuppliersRepository {
  /// One page of suppliers (inactive too), filtered by [search].
  Future<Result<List<AdminSupplier>>> getSuppliers({
    required int page,
    required int pageSize,
    String? search,
  });

  Future<Result<void>> createSupplier({
    required String code,
    required String name,
    required String districtId,
    String? contactPhone,
  });

  /// Replaces the supplier's name, district, phone and on/off.
  Future<Result<void>> updateSupplier({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
    String? contactPhone,
  });
}
