import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../domain/app_notice.dart';

class AppNoticeState extends Equatable {
  const AppNoticeState({
    this.notice = const AppNotice.off(),
    this.dismissed = false,
  });

  /// The last notice the server gave; off until the first answer.
  final AppNotice notice;

  /// The user closed this notice's banner.
  final bool dismissed;

  /// A banner for a note or warning that has not been closed.
  bool get showBanner => notice.isVisible && !notice.blocksApp && !dismissed;

  /// A "back soon" page instead of the app. It cannot be closed.
  bool get blocking => notice.blocksApp;

  @override
  List<Object?> get props => [notice, dismissed];
}

/// App-wide so every main screen shows the same message. A failed check (the
/// user is offline) keeps what was last known: the app's own offline messages
/// cover that, and a notice about the *server* would be a guess.
@lazySingleton
class AppNoticeCubit extends Cubit<AppNoticeState> {
  AppNoticeCubit(this._repository) : super(const AppNoticeState());

  final AppNoticeRepository _repository;

  Future<void> load() async {
    final result = await _repository.get();
    if (isClosed) return;
    switch (result) {
      case Ok<AppNotice>(:final value):
        // Closing a banner silences that message only; a changed or new
        // message shows again.
        emit(
          AppNoticeState(
            notice: value,
            dismissed: value == state.notice && state.dismissed,
          ),
        );
      case Err<AppNotice>():
        break;
    }
  }

  void dismiss() => emit(AppNoticeState(notice: state.notice, dismissed: true));
}
