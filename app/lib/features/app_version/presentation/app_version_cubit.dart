import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../domain/app_version.dart';

class AppVersionState extends Equatable {
  const AppVersionState({
    this.policy = const AppVersionPolicy(),
    this.installed,
  });

  /// What the server last said; no minimum until the first answer.
  final AppVersionPolicy policy;

  /// This build's version; null until read (or unreadable).
  final String? installed;

  /// This build is older than the minimum. Unknown or unreadable versions
  /// never count, so a failed check never blocks anyone.
  bool get updateRequired {
    final minimum = policy.minimumVersion;
    final mine = installed;
    return minimum != null && mine != null && isOlderThan(mine, minimum);
  }

  @override
  List<Object?> get props => [policy, installed];
}

/// App-wide: whether this build may still be used. A failed check (offline)
/// keeps what was last known.
@lazySingleton
class AppVersionCubit extends Cubit<AppVersionState> {
  AppVersionCubit(this._repository, this._installed)
    : super(const AppVersionState());

  final AppVersionRepository _repository;
  final InstalledVersion _installed;

  Future<void> load() async {
    final mine = state.installed ?? await _installed.get();
    final result = await _repository.get();
    if (isClosed) return;
    switch (result) {
      case Ok<AppVersionPolicy>(:final value):
        emit(AppVersionState(policy: value, installed: mine));
      case Err<AppVersionPolicy>():
        emit(AppVersionState(policy: state.policy, installed: mine));
    }
  }
}
