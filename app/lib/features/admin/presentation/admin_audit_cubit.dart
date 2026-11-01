import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_audit.dart';

class AdminAuditState extends Equatable {
  const AdminAuditState({
    this.status = LoadStatus.initial,
    this.entries = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<AuditEntry> entries;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminAuditState copyWith({
    LoadStatus? status,
    List<AuditEntry>? entries,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminAuditState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [status, entries, hasMore, loadingMore, failure];
}

/// The admin activity log: newest first, "load more" paging.
@injectable
class AdminAuditCubit extends Cubit<AdminAuditState> {
  AdminAuditCubit(this._repository) : super(const AdminAuditState());

  static const pageSize = 20;

  final AdminAuditRepository _repository;
  int _page = 1;

  /// First page. Entries already on screen stay until the new page arrives.
  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getEntries(page: 1, pageSize: pageSize);
    if (isClosed) return;
    switch (result) {
      case Ok<List<AuditEntry>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            entries: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AuditEntry>>(:final failure):
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
    emit(state.copyWith(loadingMore: true));
    final result = await _repository.getEntries(
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AuditEntry>>(:final value):
        _page++;
        emit(
          state.copyWith(
            entries: [...state.entries, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AuditEntry>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }
}
