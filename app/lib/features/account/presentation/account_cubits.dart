import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/data_state.dart';
import '../domain/account.dart';
import 'profile_cubit.dart';

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

/// Shows the shared [ProfileCubit] state, which the edit screens refresh.
@injectable
class MoreCubit extends Cubit<MoreState> {
  MoreCubit(this._profile, this._signOut, this._notificationService)
    : super(MoreState(profile: _profile.state)) {
    _sub = _profile.stream.listen((p) => emit(MoreState(profile: p)));
  }

  final ProfileCubit _profile;
  final SignOut _signOut;
  final NotificationService _notificationService;
  late final StreamSubscription<DataState<AccountProfile>> _sub;

  Future<void> load() => _profile.ensureLoaded();

  Future<void> retry() => _profile.load();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  Future<void> signOut() async {
    // Unregister the device token before clearing the session.
    await _notificationService.dispose();
    await _signOut();
    emit(MoreState(profile: state.profile, signedOut: true));
  }
}
