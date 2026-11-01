import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/notifications/notification_service.dart';
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
  const NotificationPrefsLoaded(
    this.prefs, {
    this.saving = false,
    this.saveFailed = false,
  });

  final NotificationPrefs prefs;
  final bool saving;

  /// The last change was not saved; [prefs] is back to the saved values.
  final bool saveFailed;

  NotificationPrefsLoaded copyWith({
    NotificationPrefs? prefs,
    bool? saving,
    bool? saveFailed,
  }) => NotificationPrefsLoaded(
    prefs ?? this.prefs,
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
  );

  @override
  List<Object?> get props => [prefs, saving, saveFailed];
}

class NotificationPrefsError extends NotificationPrefsState {
  const NotificationPrefsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Toggles apply at once and are saved after a short pause, so a burst of
/// taps is one request. A change still waiting when the screen closes is
/// saved anyway (it used to be dropped).
@injectable
class NotificationPrefsCubit extends Cubit<NotificationPrefsState> {
  NotificationPrefsCubit(this._repository, this._notifications)
    : super(const NotificationPrefsLoading());

  static const _saveDelay = Duration(milliseconds: 600);

  final NotificationPrefsRepository _repository;
  final NotificationService _notifications;
  Timer? _debounce;

  /// Waiting to be sent.
  NotificationPrefs? _pending;

  /// Last values the server confirmed.
  NotificationPrefs? _saved;

  Future<void> load() async {
    try {
      final prefs = await _repository.getPreferences();
      _saved = prefs;
      if (!isClosed) emit(NotificationPrefsLoaded(prefs));
    } catch (_) {
      if (!isClosed) emit(const NotificationPrefsError(ServerFailure()));
    }
  }

  void update(NotificationPrefs prefs) {
    final current = state;
    if (current is! NotificationPrefsLoaded) return;
    // Turning push on is when the OS permission is worth asking for.
    if (prefs.pushEnabled && !current.prefs.pushEnabled) {
      unawaited(_notifications.initialize());
    }
    emit(current.copyWith(prefs: prefs, saveFailed: false));
    _pending = prefs;
    _debounce?.cancel();
    _debounce = Timer(_saveDelay, _flush);
  }

  Future<void> _flush() async {
    final prefs = _pending;
    if (prefs == null) return;
    _pending = null;
    final current = state;
    if (!isClosed && current is NotificationPrefsLoaded) {
      emit(current.copyWith(saving: true));
    }
    final saved = await _repository.updatePreferences(prefs);
    if (saved != null) _saved = saved;
    // Closed (saved in the background) or a newer change is queued.
    if (isClosed || _pending != null) return;
    emit(
      saved != null
          ? NotificationPrefsLoaded(saved)
          : NotificationPrefsLoaded(_saved ?? prefs, saveFailed: true),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    unawaited(_flush());
    return super.close();
  }
}
