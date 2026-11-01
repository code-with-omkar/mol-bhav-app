import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../domain/admin_users.dart';

class AdminUserDetailState extends Equatable {
  const AdminUserDetailState({
    this.detail = const DataState(),
    this.busy = false,
    this.changed = false,
    this.actionFailure,
  });

  final DataState<AdminUserDetail> detail;

  /// A suspend / reinstate request is in flight.
  final bool busy;

  /// The account's standing was changed here, so the list needs a refresh.
  final bool changed;

  /// Why the last suspend / reinstate failed (shown once, then cleared).
  final Failure? actionFailure;

  AdminUserDetailState copyWith({
    DataState<AdminUserDetail>? detail,
    bool? busy,
    bool? changed,
    Failure? Function()? actionFailure,
  }) => AdminUserDetailState(
    detail: detail ?? this.detail,
    busy: busy ?? this.busy,
    changed: changed ?? this.changed,
    actionFailure: actionFailure != null ? actionFailure() : this.actionFailure,
  );

  @override
  List<Object?> get props => [detail, busy, changed, actionFailure];
}

/// One user's details, with suspend / reinstate.
@injectable
class AdminUserDetailCubit extends Cubit<AdminUserDetailState> {
  AdminUserDetailCubit(this._repository) : super(const AdminUserDetailState());

  final AdminUsersRepository _repository;

  Future<void> load(String userId) async {
    emit(state.copyWith(detail: DataState.loading(data: state.detail.data)));
    final result = await _repository.getUser(userId);
    if (isClosed) return;
    emit(state.copyWith(detail: DataState.fromResult(result)));
  }

  /// Suspends or reinstates, then reloads the user so the screen shows the new
  /// standing. A refusal (e.g. an admin account) is kept as [actionFailure].
  Future<void> setSuspended(String userId, {required bool suspend}) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, actionFailure: () => null));
    final result = await _repository.setSuspended(userId, suspend: suspend);
    if (isClosed) return;
    await result.fold(
      (failure) async =>
          emit(state.copyWith(busy: false, actionFailure: () => failure)),
      (_) async {
        emit(state.copyWith(changed: true));
        await load(userId);
        if (!isClosed) emit(state.copyWith(busy: false));
      },
    );
  }

  /// The page has shown the failure.
  void failureShown() => emit(state.copyWith(actionFailure: () => null));
}
