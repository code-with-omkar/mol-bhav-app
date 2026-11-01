import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ads.dart';

class AdminAdsState extends Equatable {
  const AdminAdsState({this.days = 30, this.data = const DataState()});

  /// The range shown: the last [days] days.
  final int days;
  final DataState<AdsOverview> data;

  @override
  List<Object?> get props => [days, data];
}

/// The ranges on offer, in days.
const adsRanges = [7, 30, 90];

@injectable
class AdminAdsCubit extends Cubit<AdminAdsState> {
  AdminAdsCubit(this._repository) : super(const AdminAdsState());

  final AdminAdsRepository _repository;

  /// Reloads the current range; the figures on screen stay while it loads, and
  /// a failed reload keeps them too.
  Future<void> load() async {
    final days = state.days;
    emit(
      AdminAdsState(
        days: days,
        data: DataState.loading(data: state.data.data),
      ),
    );
    final result = await _repository.getOverview(days: days);
    // A range picked meanwhile has its own load in flight; this one is stale.
    if (isClosed || state.days != days) return;
    emit(
      AdminAdsState(
        days: days,
        data: result.fold(
          (failure) => DataState(
            status: LoadStatus.failure,
            data: state.data.data,
            failure: failure,
          ),
          DataState.ready,
        ),
      ),
    );
  }

  Future<void> setDays(int days) {
    if (days == state.days) return Future.value();
    emit(AdminAdsState(days: days, data: state.data));
    return load();
  }
}
