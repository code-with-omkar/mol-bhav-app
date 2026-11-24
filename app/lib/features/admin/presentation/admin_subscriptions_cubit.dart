import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_subscriptions.dart';

class AdminSubscriptionsState extends Equatable {
  const AdminSubscriptionsState({
    this.status = LoadStatus.initial,
    this.subscriptions = const [],
    this.filter,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for a first page or a new filter, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminSubscription> subscriptions;

  /// Only subscriptions in this state; null = all of them.
  final SubscriptionState? filter;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminSubscriptionsState copyWith({
    LoadStatus? status,
    List<AdminSubscription>? subscriptions,
    SubscriptionState? Function()? filter,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminSubscriptionsState(
    status: status ?? this.status,
    subscriptions: subscriptions ?? this.subscriptions,
    filter: filter != null ? filter() : this.filter,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    subscriptions,
    filter,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// Who has a plan: a state filter, "load more" paging, and ending an active
/// subscription early. It opens on the active ones.
@injectable
class AdminSubscriptionsCubit extends Cubit<AdminSubscriptionsState> {
  AdminSubscriptionsCubit(this._repository)
    : super(const AdminSubscriptionsState(filter: SubscriptionState.active));

  static const pageSize = 20;

  final AdminSubscriptionsRepository _repository;
  int _page = 1;
  int _generation = 0;

  /// First page for the current filter. Rows already on screen stay until the
  /// new page arrives.
  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getSubscriptions(
      status: state.filter,
      page: 1,
      pageSize: pageSize,
    );
    // A newer filter has its own request in flight.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminSubscription>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            subscriptions: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminSubscription>>(:final failure):
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
    final result = await _repository.getSubscriptions(
      status: state.filter,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminSubscription>>(:final value):
        _page++;
        emit(
          state.copyWith(
            subscriptions: [...state.subscriptions, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminSubscription>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> setFilter(SubscriptionState? filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: () => filter));
    return load();
  }

  /// Ends [subscription] now, then rereads the list. Null on success, else why
  /// it failed. Only an active subscription can be ended.
  Future<Failure?> end(AdminSubscription subscription) async {
    if (!subscription.canEnd) return null;
    final result = await _repository.expire(subscription.id);
    if (isClosed) return null;
    switch (result) {
      case Err<void>(:final failure):
        return failure;
      case Ok<void>():
        await load();
        return null;
    }
  }
}
