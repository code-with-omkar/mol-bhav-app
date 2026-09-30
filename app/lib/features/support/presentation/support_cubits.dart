import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/support.dart';

class HelpSupportState extends Equatable {
  const HelpSupportState({
    this.faq = const DataState(),
    this.contact = const DataState(),
    this.expanded,
  });

  final DataState<List<FaqEntry>> faq;
  final DataState<SupportContact> contact;

  /// Index of the open accordion row; `null` means all collapsed.
  final int? expanded;

  @override
  List<Object?> get props => [faq, contact, expanded];
}

/// FAQ + contact details for the Help & Support screen. Both are reference
/// data, so a repeat visit is served from the cache.
@injectable
class HelpSupportCubit extends Cubit<HelpSupportState> {
  HelpSupportCubit(this._getFaq, this._getContact)
    : super(const HelpSupportState());

  final GetSupportFaq _getFaq;
  final GetSupportContact _getContact;

  Future<void> load() async {
    emit(
      HelpSupportState(
        faq: DataState.loading(data: state.faq.data),
        contact: DataState.loading(data: state.contact.data),
        expanded: state.expanded,
      ),
    );
    final (faq, contact) = await (_getFaq(), _getContact()).wait;
    if (isClosed) return;
    emit(
      HelpSupportState(
        faq: DataState.fromResult(faq),
        contact: DataState.fromResult(contact),
        expanded: state.expanded,
      ),
    );
  }

  /// Accordion: opening a row closes the one before it.
  void toggle(int index) => emit(
    HelpSupportState(
      faq: state.faq,
      contact: state.contact,
      expanded: state.expanded == index ? null : index,
    ),
  );
}

class RaiseTicketState extends Equatable {
  const RaiseTicketState({
    this.category = TicketCategory.data,
    this.subject = '',
    this.message = '',
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
    this.createdId,
  });

  final TicketCategory category;
  final String subject;
  final String message;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  /// Set once the ticket exists, so the page can open its thread.
  final String? createdId;

  /// Mirrors the API's own limits, so the button is only enabled for a
  /// request that can actually succeed.
  static const subjectMinLength = 5;
  static const subjectMaxLength = 120;
  static const messageMaxLength = 2000;

  bool get isSubjectValid {
    final trimmed = subject.trim().length;
    return trimmed >= subjectMinLength && trimmed <= subjectMaxLength;
  }

  bool get isMessageValid {
    final trimmed = message.trim().length;
    return trimmed >= 1 && trimmed <= messageMaxLength;
  }

  bool get canSubmit =>
      isSubjectValid &&
      isMessageValid &&
      submitStatus != SubmitStatus.submitting;

  RaiseTicketState copyWith({
    TicketCategory? category,
    String? subject,
    String? message,
    SubmitStatus? submitStatus,
    Failure? submitFailure,
    ValueGetter<String?>? createdId,
  }) => RaiseTicketState(
    category: category ?? this.category,
    subject: subject ?? this.subject,
    message: message ?? this.message,
    submitStatus: submitStatus ?? SubmitStatus.idle,
    submitFailure: submitFailure,
    createdId: createdId != null ? createdId() : this.createdId,
  );

  @override
  List<Object?> get props => [
    category,
    subject,
    message,
    submitStatus,
    submitFailure,
    createdId,
  ];
}

@injectable
class RaiseTicketCubit extends Cubit<RaiseTicketState> {
  RaiseTicketCubit(this._createTicket) : super(const RaiseTicketState());

  final CreateSupportTicket _createTicket;

  void selectCategory(TicketCategory category) =>
      emit(state.copyWith(category: category));

  void subjectChanged(String value) => emit(state.copyWith(subject: value));

  void messageChanged(String value) => emit(state.copyWith(message: value));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _createTicket(
      NewTicket(
        category: state.category,
        subject: state.subject.trim(),
        message: state.message.trim(),
      ),
    );
    if (isClosed) return;
    emit(
      result.fold(
        (f) => state.copyWith(
          submitStatus: SubmitStatus.failure,
          submitFailure: f,
        ),
        (id) => state.copyWith(
          submitStatus: SubmitStatus.success,
          createdId: () => id,
        ),
      ),
    );
  }
}

@injectable
class MyTicketsCubit extends Cubit<DataState<List<SupportTicketSummary>>> {
  MyTicketsCubit(this._getTickets) : super(const DataState());

  final GetSupportTickets _getTickets;

  Future<void> load() async {
    emit(DataState.loading(data: state.data));
    final result = await _getTickets();
    if (isClosed) return;
    emit(DataState.fromResult(result));
  }
}

class TicketThreadState extends Equatable {
  const TicketThreadState({
    this.thread = const DataState(),
    this.draft = '',
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
  });

  final DataState<SupportTicketThread> thread;
  final String draft;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  bool get canSend =>
      draft.trim().isNotEmpty &&
      draft.trim().length <= RaiseTicketState.messageMaxLength &&
      (thread.data?.canReply ?? false) &&
      submitStatus != SubmitStatus.submitting;

  TicketThreadState copyWith({
    DataState<SupportTicketThread>? thread,
    String? draft,
    SubmitStatus? submitStatus,
    Failure? submitFailure,
  }) => TicketThreadState(
    thread: thread ?? this.thread,
    draft: draft ?? this.draft,
    submitStatus: submitStatus ?? SubmitStatus.idle,
    submitFailure: submitFailure,
  );

  @override
  List<Object?> get props => [thread, draft, submitStatus, submitFailure];
}

/// One ticket's conversation. A sent reply refetches the thread, so the new
/// message and any status change the API made arrive together.
@injectable
class TicketThreadCubit extends Cubit<TicketThreadState> {
  TicketThreadCubit(this._getTicket, this._reply)
    : super(const TicketThreadState());

  final GetSupportTicket _getTicket;
  final ReplyToSupportTicket _reply;
  String? _ticketId;

  Future<void> load(String ticketId) {
    _ticketId = ticketId;
    return refresh();
  }

  Future<void> refresh() async {
    final ticketId = _ticketId;
    if (ticketId == null) return;
    emit(state.copyWith(thread: DataState.loading(data: state.thread.data)));
    final result = await _getTicket(ticketId);
    if (isClosed) return;
    emit(state.copyWith(thread: DataState.fromResult(result)));
  }

  void draftChanged(String value) => emit(state.copyWith(draft: value));

  Future<void> send() async {
    final ticketId = _ticketId;
    if (ticketId == null || !state.canSend) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _reply(ticketId, state.draft.trim());
    if (isClosed) return;
    switch (result) {
      case Err(:final failure):
        emit(
          state.copyWith(
            submitStatus: SubmitStatus.failure,
            submitFailure: failure,
          ),
        );
      case Ok():
        emit(state.copyWith(draft: '', submitStatus: SubmitStatus.success));
        await refresh();
    }
  }
}
