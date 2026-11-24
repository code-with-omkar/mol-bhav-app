import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_units.dart';

/// The catalog's units of measure: add, rename, show or hide.
@injectable
class AdminUnitsCubit extends Cubit<DataState<List<AdminUnit>>> {
  AdminUnitsCubit(this._repository) : super(const DataState());

  final AdminUnitsRepository _repository;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _repository.getUnits();
    if (isClosed) return;
    emit(DataState.fromResult(result));
  }

  /// Each save returns null on success (the list is reread), else why not.
  Future<Failure?> create({
    required String code,
    required String symbol,
    required UnitDimension dimension,
    required double toBaseFactor,
    required Map<String, String> names,
  }) => _then(
    () => _repository.createUnit(
      code: code,
      symbol: symbol,
      dimension: dimension,
      toBaseFactor: toBaseFactor,
      names: names,
    ),
  );

  Future<Failure?> update(AdminUnit unit) =>
      _then(() => _repository.updateUnit(unit));

  Future<Failure?> _then(Future<Result<void>> Function() save) async {
    final result = await save();
    if (isClosed) return null;
    switch (result) {
      case Err<void>(:final failure):
        return failure;
      case Ok<void>():
        await load();
        return null;
    }
  }
}
