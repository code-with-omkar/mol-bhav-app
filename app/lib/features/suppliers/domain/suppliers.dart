import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// A regional supplier or hub a buyer can contact.
class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    required this.districtName,
    required this.stateName,
    this.contactPhone,
  });

  final String id;
  final String name;
  final String districtName;
  final String stateName;
  final String? contactPhone;

  /// The phone with spaces and dashes removed, ready for a `tel:` link; null
  /// when the supplier has none.
  String? get dialNumber {
    final raw = contactPhone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    return raw.isEmpty ? null : raw;
  }

  @override
  List<Object?> get props => [id, name, districtName, stateName, contactPhone];
}

abstract interface class SuppliersRepository {
  Future<Result<List<Supplier>>> getSuppliers({
    required int page,
    required int pageSize,
    String? search,
  });
}
