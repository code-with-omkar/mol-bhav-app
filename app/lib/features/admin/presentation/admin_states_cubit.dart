import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_states.dart';

/// The states and their districts: add, rename, show or hide.
@injectable
class AdminStatesCubit extends Cubit<DataState<List<AdminState>>> {
  AdminStatesCubit(this._repository) : super(const DataState());

  final AdminStatesRepository _repository;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _repository.getStates();
    if (isClosed) return;
    emit(DataState.fromResult(result));
  }

  /// Each save returns null on success (the list is reread), else why not.
  Future<Failure?> createState(String name, String code) =>
      _then(() => _repository.createState(name: name, code: code));

  Future<Failure?> updateState(String id, String name, bool isActive) => _then(
    () => _repository.updateState(id: id, name: name, isActive: isActive),
  );

  Future<Failure?> addDistrict(String stateId, String name) =>
      _then(() => _repository.addDistrict(stateId: stateId, name: name));

  Future<Failure?> updateDistrict(
    String stateId,
    String id,
    String name,
    bool isActive,
  ) => _then(
    () => _repository.updateDistrict(
      stateId: stateId,
      id: id,
      name: name,
      isActive: isActive,
    ),
  );

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
