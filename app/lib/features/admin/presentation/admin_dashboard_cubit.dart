import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_dashboard.dart';

/// The admin landing screen's numbers. A refresh keeps the figures on screen
/// while the new ones load, and a failed refresh keeps them too.
@injectable
class AdminDashboardCubit extends Cubit<DataState<AdminDashboard>> {
  AdminDashboardCubit(this._repository) : super(const DataState());

  final AdminDashboardRepository _repository;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _repository.getOverview();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => DataState(
          status: LoadStatus.failure,
          data: state.data,
          failure: failure,
        ),
        DataState.ready,
      ),
    );
  }
}
