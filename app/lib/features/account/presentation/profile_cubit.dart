import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/locale/locale_cubit.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/account.dart';

/// The signed-in user's profile, shared by Home and More. Screens that change
/// the profile call [refresh] after saving; a language change refreshes it
/// too, since the API localises names. Cleared when the session ends.
@lazySingleton
class ProfileCubit extends Cubit<DataState<AccountProfile>> {
  ProfileCubit(this._watch, this._invalidate, this._session, LocaleCubit locale)
    : super(const DataState()) {
    _session.addListener(_onSession);
    _localeSub = locale.stream.listen((_) => refresh());
  }

  final WatchAccountProfile _watch;
  final InvalidateAccountProfile _invalidate;
  final SessionManager _session;
  late final StreamSubscription<Object?> _localeSub;

  /// Bumped per load so an older, slower load can't overwrite a newer one.
  int _generation = 0;

  Future<void> load() async {
    if (!_session.hasSession) return;
    final generation = ++_generation;
    await for (final next in revalidate(_watch(), current: state.data)) {
      if (isClosed || generation != _generation) return;
      emit(next);
    }
  }

  /// Loads once per session; later calls reuse the shared state.
  Future<void> ensureLoaded() =>
      state.status == LoadStatus.initial ? load() : Future.value();

  /// Refetches after a profile change, skipping the stale cached copy.
  Future<void> refresh() async {
    await _invalidate();
    await load();
  }

  void _onSession() {
    if (_session.hasSession) return;
    _generation++;
    emit(const DataState());
  }

  @override
  Future<void> close() {
    _session.removeListener(_onSession);
    _localeSub.cancel();
    return super.close();
  }
}
