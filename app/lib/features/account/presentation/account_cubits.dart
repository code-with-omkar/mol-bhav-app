import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../domain/account.dart';

class MoreState extends Equatable {
  const MoreState({
    this.profile = const DataState(),
    this.actionFailure,
    this.signedOut = false,
  });

  final DataState<AccountProfile> profile;

  /// A toggle that failed to save (shown once, then cleared).
  final Failure? actionFailure;
  final bool signedOut;

  @override
  List<Object?> get props => [profile, actionFailure, signedOut];
}

@injectable
class MoreCubit extends Cubit<MoreState> {
  MoreCubit(this._getProfile, this._updateNotifications, this._signOut)
    : super(const MoreState());

  final GetAccountProfile _getProfile;
  final UpdateNotifications _updateNotifications;
  final SignOut _signOut;

  Future<void> load() async {
    emit(MoreState(profile: DataState.loading(data: state.profile.data)));
    emit(MoreState(profile: DataState.fromResult(await _getProfile())));
  }

  Future<void> setPush(bool on) => _setNotifications(push: on);

  Future<void> setWhatsapp(bool on) => _setNotifications(whatsapp: on);

  /// Optimistic: flips the switch, reverts if the save fails.
  Future<void> _setNotifications({bool? push, bool? whatsapp}) async {
    final before = state.profile.data;
    if (before == null) return;
    final after = before.withNotifications(push: push, whatsapp: whatsapp);
    emit(MoreState(profile: DataState.ready(after)));
    final result = await _updateNotifications(
      push: after.pushEnabled,
      whatsapp: after.whatsappEnabled,
    );
    result.fold(
      (failure) => emit(
        MoreState(profile: DataState.ready(before), actionFailure: failure),
      ),
      (_) {},
    );
  }

  Future<void> signOut() async {
    await _signOut();
    emit(MoreState(profile: state.profile, signedOut: true));
  }
}

@injectable
class SubscriptionCubit extends Cubit<DataState<List<SubscriptionPlan>>> {
  SubscriptionCubit(this._getPlans) : super(const DataState());

  final GetPlans _getPlans;

  Future<void> load() async {
    emit(const DataState.loading());
    emit(DataState.fromResult(await _getPlans()));
  }
}
