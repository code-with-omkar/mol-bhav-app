import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_billing.dart';

/// The subscription plans: list, add, and edit name, price and on/off.
@injectable
class AdminPlansCubit extends Cubit<DataState<List<AdminPlan>>> {
  AdminPlansCubit(this._repository) : super(const DataState());

  final AdminBillingRepository _repository;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _repository.getPlans();
    if (isClosed) return;
    emit(DataState.fromResult(result));
  }

  /// Adds a plan; null on success (the list is reread), else why it failed.
  Future<Failure?> create(PlanDraft draft) =>
      _then(() => _repository.createPlan(draft));

  /// Saves a plan's name, price and on/off; null on success, else why not.
  Future<Failure?> update(String id, PlanDraft draft) =>
      _then(() => _repository.updatePlan(id, draft));

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
