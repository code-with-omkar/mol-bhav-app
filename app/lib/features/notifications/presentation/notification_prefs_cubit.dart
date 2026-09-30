import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../domain/notification_prefs.dart';

sealed class NotificationPrefsState extends Equatable {
  const NotificationPrefsState();
}

class NotificationPrefsLoading extends NotificationPrefsState {
  const NotificationPrefsLoading();

  @override
  List<Object?> get props => [];
}

class NotificationPrefsLoaded extends NotificationPrefsState {
  const NotificationPrefsLoaded(this.prefs, {this.saving = false});

  final NotificationPrefs prefs;
  final bool saving;

  NotificationPrefsLoaded copyWith({NotificationPrefs? prefs, bool? saving}) =>
      NotificationPrefsLoaded(
        prefs ?? this.prefs,
        saving: saving ?? this.saving,
      );

  @override
  List<Object?> get props => [prefs, saving];
}

class NotificationPrefsError extends NotificationPrefsState {
  const NotificationPrefsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@injectable
class NotificationPrefsCubit extends Cubit<NotificationPrefsState> {
  NotificationPrefsCubit(this._repository)
    : super(const NotificationPrefsLoading());

  final NotificationPrefsRepository _repository;
  Timer? _debounce;

  Future<void> load() async {
    try {
      final prefs = await _repository.getPreferences();
      emit(NotificationPrefsLoaded(prefs));
    } catch (_) {
      emit(const NotificationPrefsError(ServerFailure()));
    }
  }

  void update(NotificationPrefs prefs) {
    final current = state;
    if (current is! NotificationPrefsLoaded) return;
    emit(current.copyWith(prefs: prefs));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _save(prefs));
  }

  Future<void> _save(NotificationPrefs prefs) async {
    final current = state;
    if (current is! NotificationPrefsLoaded) return;
    emit(current.copyWith(saving: true));
    final saved = await _repository.updatePreferences(prefs);
    emit(NotificationPrefsLoaded(saved));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
