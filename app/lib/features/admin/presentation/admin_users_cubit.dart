import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_users.dart';

class AdminUsersState extends Equatable {
  const AdminUsersState({
    this.status = LoadStatus.initial,
    this.users = const [],
    this.query = '',
    this.filter = UserListFilter.all,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for a first page or a fresh search, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminUser> users;
  final String query;
  final UserListFilter filter;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminUsersState copyWith({
    LoadStatus? status,
    List<AdminUser>? users,
    String? query,
    UserListFilter? filter,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminUsersState(
    status: status ?? this.status,
    users: users ?? this.users,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    users,
    query,
    filter,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// The admin user list: search, a status filter and "load more" paging.
@injectable
class AdminUsersCubit extends Cubit<AdminUsersState> {
  AdminUsersCubit(this._repository) : super(const AdminUsersState());

  static const pageSize = 20;

  final AdminUsersRepository _repository;
  int _page = 1;
  int _generation = 0;

  /// First page for the current search and filter. Users already on screen
  /// stay until the new page arrives.
  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getUsers(
      search: state.query,
      filter: state.filter,
      page: 1,
      pageSize: pageSize,
    );
    // A newer search or filter has its own request in flight.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminUser>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            users: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminUser>>(:final failure):
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
    final result = await _repository.getUsers(
      search: state.query,
      filter: state.filter,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminUser>>(:final value):
        _page++;
        emit(
          state.copyWith(
            users: [...state.users, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminUser>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> search(String query) {
    final trimmed = query.trim();
    if (trimmed == state.query) return Future.value();
    emit(state.copyWith(query: trimmed));
    return load();
  }

  Future<void> setFilter(UserListFilter filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: filter));
    return load();
  }
}
