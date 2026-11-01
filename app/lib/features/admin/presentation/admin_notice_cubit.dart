import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../app_notice/domain/app_notice.dart';
import '../../app_notice/presentation/app_notice_cubit.dart';

class AdminNoticeState extends Equatable {
  const AdminNoticeState({
    this.notice = const DataState(),
    this.saving = false,
    this.saves = 0,
    this.saveFailure,
  });

  /// The notice as saved (an off notice keeps its text).
  final DataState<AppNotice> notice;

  final bool saving;

  /// How many saves have succeeded; the page shows "Saved" when it grows.
  final int saves;

  /// Why the last save failed (shown once, then cleared).
  final Failure? saveFailure;

  AdminNoticeState copyWith({
    DataState<AppNotice>? notice,
    bool? saving,
    int? saves,
    Failure? Function()? saveFailure,
  }) => AdminNoticeState(
    notice: notice ?? this.notice,
    saving: saving ?? this.saving,
    saves: saves ?? this.saves,
    saveFailure: saveFailure != null ? saveFailure() : this.saveFailure,
  );

  @override
  List<Object?> get props => [notice, saving, saves, saveFailure];
}

/// The editor for the message every user sees (note, warning or maintenance).
@injectable
class AdminNoticeCubit extends Cubit<AdminNoticeState> {
  AdminNoticeCubit(this._repository, this._userNotice)
    : super(const AdminNoticeState());

  final AppNoticeRepository _repository;

  /// The app-wide copy users' screens read; refreshed after a save so an admin
  /// viewing the app as a user sees the change at once.
  final AppNoticeCubit _userNotice;

  Future<void> load() async {
    emit(state.copyWith(notice: DataState.loading(data: state.notice.data)));
    final result = await _repository.getForEditing();
    if (isClosed) return;
    emit(state.copyWith(notice: DataState.fromResult(result)));
  }

  Future<void> save(AppNotice notice) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, saveFailure: () => null));
    final result = await _repository.save(notice);
    if (isClosed) return;
    await result.fold(
      (failure) async =>
          emit(state.copyWith(saving: false, saveFailure: () => failure)),
      (_) async {
        emit(
          state.copyWith(
            saving: false,
            saves: state.saves + 1,
            notice: DataState.ready(notice),
          ),
        );
        await _userNotice.load();
      },
    );
  }

  void failureShown() => emit(state.copyWith(saveFailure: () => null));
}
