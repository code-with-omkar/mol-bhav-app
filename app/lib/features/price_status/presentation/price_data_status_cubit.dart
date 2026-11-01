import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../domain/price_data_status.dart';

class PriceDataStatusState extends Equatable {
  const PriceDataStatusState({this.status, this.dismissed = false});

  /// The last status the server gave; `null` until the first answer.
  final PriceDataStatus? status;

  /// The user closed the banner for the current problem.
  final bool dismissed;

  /// Show the banner: prices are delayed and the user has not closed it.
  bool get showBanner => (status?.isDelayed ?? false) && !dismissed;

  @override
  List<Object?> get props => [status, dismissed];
}

/// App-wide so every main screen shows the same banner. A failed check (the
/// user is offline) keeps what was last known — the app's own offline
/// messages cover that case, and a banner about the *server's* data would be
/// a guess.
@lazySingleton
class PriceDataStatusCubit extends Cubit<PriceDataStatusState> {
  PriceDataStatusCubit(this._repository) : super(const PriceDataStatusState());

  final PriceDataStatusRepository _repository;

  Future<void> load() async {
    final result = await _repository.getStatus();
    if (isClosed) return;
    switch (result) {
      case Ok<PriceDataStatus>(:final value):
        // Closing the banner only silences the problem it was closed for: a
        // recovery, or a different outage later, shows it again.
        final sameProblem =
            state.status?.isDelayed == value.isDelayed &&
            state.status?.lastUpdatedAt == value.lastUpdatedAt;
        emit(
          PriceDataStatusState(
            status: value,
            dismissed: sameProblem && state.dismissed,
          ),
        );
      case Err<PriceDataStatus>():
        break;
    }
  }

  void dismiss() =>
      emit(PriceDataStatusState(status: state.status, dismissed: true));
}
