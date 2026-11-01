import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../domain/app_features.dart';

class FeatureSwitchesState extends Equatable {
  const FeatureSwitchesState([this.flags = const {}]);

  /// What the server last said; empty until the first answer.
  final Map<AppFeature, bool> flags;

  /// A feature is on unless the server says it is off, so a slow or failed
  /// first check never hides anything.
  bool isOn(AppFeature feature) => flags[feature] ?? true;

  @override
  List<Object?> get props => [flags];
}

/// App-wide so every screen hides a switched-off feature the same way. A
/// failed check (the user is offline) keeps what was last known.
@lazySingleton
class FeatureSwitchesCubit extends Cubit<FeatureSwitchesState> {
  FeatureSwitchesCubit(this._repository) : super(const FeatureSwitchesState());

  final AppFeaturesRepository _repository;

  Future<void> load() async {
    final result = await _repository.getAll();
    if (isClosed) return;
    switch (result) {
      case Ok<Map<AppFeature, bool>>(:final value):
        emit(FeatureSwitchesState(value));
      case Err<Map<AppFeature, bool>>():
        break;
    }
  }

  /// An admin changed [feature] here: show it at once instead of waiting for
  /// the next check.
  void apply(AppFeature feature, {required bool enabled}) =>
      emit(FeatureSwitchesState({...state.flags, feature: enabled}));
}

extension FeatureSwitchesX on BuildContext {
  /// Whether [feature] is on. Rebuilds when an admin changes it. Without the
  /// cubit above (a screen shown on its own) everything is on.
  bool featureOn(AppFeature feature) {
    try {
      return select<FeatureSwitchesCubit, bool>((c) => c.state.isOn(feature));
    } on Object {
      return true;
    }
  }
}
