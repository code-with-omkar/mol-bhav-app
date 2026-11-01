import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../../support/domain/support.dart';
import '../domain/admin_support.dart';

class AdminTicketThreadState extends Equatable {
  const AdminTicketThreadState({
    this.thread = const DataState(),
    this.busy = false,
    this.changes = 0,
    this.replies = 0,
    this.actionFailure,
  });

  final DataState<SupportTicketThread> thread;

  /// A reply or status change is in flight.
  final bool busy;

  /// How many replies or status changes have been saved here; the queue
  /// refreshes when the page closes with a non-zero count.
  final int changes;

  /// How many replies have been sent; the page clears its draft when it grows.
  final int replies;

  /// Why the last reply or status change failed (shown once, then cleared).
  final Failure? actionFailure;

  AdminTicketThreadState copyWith({
    DataState<SupportTicketThread>? thread,
    bool? busy,
    int? changes,
    int? replies,
    Failure? Function()? actionFailure,
  }) => AdminTicketThreadState(
    thread: thread ?? this.thread,
    busy: busy ?? this.busy,
    changes: changes ?? this.changes,
    replies: replies ?? this.replies,
    actionFailure: actionFailure != null ? actionFailure() : this.actionFailure,
  );

  @override
  List<Object?> get props => [thread, busy, changes, replies, actionFailure];
}

/// One ticket for support: read it, reply, change its status.
@injectable
class AdminTicketThreadCubit extends Cubit<AdminTicketThreadState> {
  AdminTicketThreadCubit(this._repository)
    : super(const AdminTicketThreadState());

  final AdminSupportRepository _repository;
  String _ticketId = '';

  Future<void> load(String ticketId) async {
    _ticketId = ticketId;
    emit(state.copyWith(thread: DataState.loading(data: state.thread.data)));
    final result = await _repository.getTicket(ticketId);
    if (isClosed) return;
    emit(state.copyWith(thread: DataState.fromResult(result)));
  }

  Future<void> refresh() => load(_ticketId);

  /// Sends [message] as support, then reloads the conversation. An empty
  /// message is not sent.
  Future<void> reply(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    await _act(() => _repository.reply(_ticketId, text), reply: true);
  }

  Future<void> setStatus(TicketStatus status) {
    if (status == state.thread.data?.status) return Future.value();
    return _act(() => _repository.setStatus(_ticketId, status));
  }

  Future<void> _act(
    Future<Result<void>> Function() run, {
    bool reply = false,
  }) async {
    if (state.busy || _ticketId.isEmpty) return;
    emit(state.copyWith(busy: true, actionFailure: () => null));
    final result = await run();
    if (isClosed) return;
    await result.fold(
      (failure) async =>
          emit(state.copyWith(busy: false, actionFailure: () => failure)),
      (_) async {
        emit(
          state.copyWith(
            busy: false,
            changes: state.changes + 1,
            replies: reply ? state.replies + 1 : state.replies,
          ),
        );
        // Read back what the server now says (a reply moves Open to In progress).
        await load(_ticketId);
      },
    );
  }

  void failureShown() => emit(state.copyWith(actionFailure: () => null));
}
