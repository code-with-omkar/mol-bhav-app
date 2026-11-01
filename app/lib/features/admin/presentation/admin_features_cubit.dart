import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../app_features/domain/app_features.dart';
import '../../app_features/presentation/feature_switches_cubit.dart';

class AdminFeaturesState extends Equatable {
  const AdminFeaturesState({
    this.flags = const DataState(),
    this.saving = const {},
    this.saveFailure,
  });

  final DataState<Map<AppFeature, bool>> flags;

  /// Features whose change is being saved.
  final Set<AppFeature> saving;

  /// Why the last change failed (shown once, then cleared).
  final Failure? saveFailure;

  AdminFeaturesState copyWith({
    DataState<Map<AppFeature, bool>>? flags,
    Set<AppFeature>? saving,
    Failure? Function()? saveFailure,
  }) => AdminFeaturesState(
    flags: flags ?? this.flags,
    saving: saving ?? this.saving,
    saveFailure: saveFailure != null ? saveFailure() : this.saveFailure,
  );

  @override
  List<Object?> get props => [flags, saving, saveFailure];
}

/// The admin's list of switches. A change shows at once and is put back if
/// the server refuses it.
@injectable
class AdminFeaturesCubit extends Cubit<AdminFeaturesState> {
  AdminFeaturesCubit(this._repository, this._userFeatures)
    : super(const AdminFeaturesState());

  final AppFeaturesRepository _repository;

  /// The app-wide copy users' screens read; updated after a change so an admin
  /// viewing the app as a user sees it at once.
  final FeatureSwitchesCubit _userFeatures;

  Future<void> load() async {
    emit(state.copyWith(flags: DataState.loading(data: state.flags.data)));
    final result = await _repository.getAll();
    if (isClosed) return;
    emit(state.copyWith(flags: DataState.fromResult(result)));
  }

  Future<void> setEnabled(AppFeature feature, {required bool enabled}) async {
    final current = state.flags.data;
    if (current == null || state.saving.contains(feature)) return;
    emit(
      state.copyWith(
        flags: DataState.ready({...current, feature: enabled}),
        saving: {...state.saving, feature},
        saveFailure: () => null,
      ),
    );
    final result = await _repository.set(feature, enabled: enabled);
    if (isClosed) return;
    final stillSaving = {...state.saving}..remove(feature);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          // Back to what the server has.
          flags: DataState.ready({...?state.flags.data, feature: !enabled}),
          saving: stillSaving,
          saveFailure: () => failure,
        ),
      ),
      (_) async {
        emit(state.copyWith(saving: stillSaving));
        _userFeatures.apply(feature, enabled: enabled);
      },
    );
  }

  void failureShown() => emit(state.copyWith(saveFailure: () => null));
}
