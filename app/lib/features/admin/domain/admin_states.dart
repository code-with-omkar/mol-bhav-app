import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Longest state / district name the API accepts.
const stateNameMaxLength = 100;

/// A state code is 2 to 10 letters or digits (stored in capitals).
const stateCodeMinLength = 2;
const stateCodeMaxLength = 10;

class AdminDistrict extends Equatable {
  const AdminDistrict({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, isActive];
}

/// A state with its districts.
class AdminState extends Equatable {
  const AdminState({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.districts = const [],
  });

  final String id;
  final String name;
  final String code;
  final bool isActive;
  final List<AdminDistrict> districts;

  @override
  List<Object?> get props => [id, name, code, isActive, districts];
}

final _stateCode = RegExp(r'^[A-Za-z0-9]{2,10}$');

bool isValidStateCode(String code) => _stateCode.hasMatch(code.trim());

enum PlaceProblem { nameMissing, nameTooLong, codeInvalid }

/// What is wrong with a state or district being saved. The code is only
/// checked when [needsCode] (a new state; it cannot be changed afterwards).
Set<PlaceProblem> placeProblems({
  required String name,
  required bool needsCode,
  String code = '',
}) => {
  if (name.trim().isEmpty) PlaceProblem.nameMissing,
  if (name.trim().length > stateNameMaxLength) PlaceProblem.nameTooLong,
  if (needsCode && !isValidStateCode(code)) PlaceProblem.codeInvalid,
};

abstract interface class AdminStatesRepository {
  /// Every state (inactive too) with its districts.
  Future<Result<List<AdminState>>> getStates();

  Future<Result<void>> createState({
    required String name,
    required String code,
  });

  Future<Result<void>> updateState({
    required String id,
    required String name,
    required bool isActive,
  });

  Future<Result<void>> addDistrict({
    required String stateId,
    required String name,
  });

  Future<Result<void>> updateDistrict({
    required String stateId,
    required String id,
    required String name,
    required bool isActive,
  });
}
