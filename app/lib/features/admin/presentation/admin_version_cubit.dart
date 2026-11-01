import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../app_version/domain/app_version.dart';
import '../../app_version/presentation/app_version_cubit.dart';

class AdminVersionState extends Equatable {
  const AdminVersionState({
    this.policy = const DataState(),
    this.saving = false,
    this.saves = 0,
    this.saveFailure,
  });

  final DataState<AppVersionPolicy> policy;
  final bool saving;

  /// How many saves have succeeded; the page shows "Saved" when it grows.
  final int saves;

  /// Why the last save failed (shown once, then cleared).
  final Failure? saveFailure;

  AdminVersionState copyWith({
    DataState<AppVersionPolicy>? policy,
    bool? saving,
    int? saves,
    Failure? Function()? saveFailure,
  }) => AdminVersionState(
    policy: policy ?? this.policy,
    saving: saving ?? this.saving,
    saves: saves ?? this.saves,
    saveFailure: saveFailure != null ? saveFailure() : this.saveFailure,
  );

  @override
  List<Object?> get props => [policy, saving, saves, saveFailure];
}

/// The editor for the minimum app version and its update link.
@injectable
class AdminVersionCubit extends Cubit<AdminVersionState> {
  AdminVersionCubit(this._repository, this._userVersion)
    : super(const AdminVersionState());

  final AppVersionRepository _repository;

  /// The app-wide copy that decides whether this phone is blocked; refreshed
  /// after a save.
  final AppVersionCubit _userVersion;

  Future<void> load() async {
    emit(state.copyWith(policy: DataState.loading(data: state.policy.data)));
    final result = await _repository.get();
    if (isClosed) return;
    emit(state.copyWith(policy: DataState.fromResult(result)));
  }

  Future<void> save(AppVersionPolicy policy) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, saveFailure: () => null));
    final result = await _repository.save(policy);
    if (isClosed) return;
    await result.fold(
      (failure) async =>
          emit(state.copyWith(saving: false, saveFailure: () => failure)),
      (_) async {
        // Read back what the server stored (it writes 1.2 as 1.2.0).
        emit(state.copyWith(saving: false, saves: state.saves + 1));
        await load();
        await _userVersion.load();
      },
    );
  }

  void failureShown() => emit(state.copyWith(saveFailure: () => null));
}
