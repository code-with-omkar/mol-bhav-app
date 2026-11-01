import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../../support/domain/support.dart';
import '../domain/admin_support.dart';

class AdminTicketsState extends Equatable {
  const AdminTicketsState({
    this.status = LoadStatus.initial,
    this.tickets = const [],
    this.filter,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for a first page or a new filter, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminTicket> tickets;

  /// Only tickets in this status; null = every ticket.
  final TicketStatus? filter;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminTicketsState copyWith({
    LoadStatus? status,
    List<AdminTicket>? tickets,
    TicketStatus? Function()? filter,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminTicketsState(
    status: status ?? this.status,
    tickets: tickets ?? this.tickets,
    filter: filter != null ? filter() : this.filter,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    tickets,
    filter,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// The support queue: a status filter and "load more" paging. It opens on
/// tickets that still need an answer.
@injectable
class AdminTicketsCubit extends Cubit<AdminTicketsState> {
  AdminTicketsCubit(this._repository)
    : super(const AdminTicketsState(filter: TicketStatus.open));

  static const pageSize = 20;

  final AdminSupportRepository _repository;
  int _page = 1;
  int _generation = 0;

  /// First page for the current filter. Tickets already on screen stay until
  /// the new page arrives.
  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getTickets(
      status: state.filter,
      page: 1,
      pageSize: pageSize,
    );
    // A newer filter has its own request in flight.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminTicket>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            tickets: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminTicket>>(:final failure):
        emit(
          state.copyWith(status: LoadStatus.failure, failure: () => failure),
        );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != LoadStatus.ready) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    final result = await _repository.getTickets(
      status: state.filter,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminTicket>>(:final value):
        _page++;
        emit(
          state.copyWith(
            tickets: [...state.tickets, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminTicket>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> setFilter(TicketStatus? filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: () => filter));
    return load();
  }
}
