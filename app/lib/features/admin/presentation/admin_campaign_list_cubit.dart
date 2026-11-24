import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ads.dart';
import '../domain/admin_campaigns.dart';

class AdminCampaignListState extends Equatable {
  const AdminCampaignListState({
    this.status = LoadStatus.initial,
    this.campaigns = const [],
    this.filter,
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for a first page or a new filter, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminCampaign> campaigns;

  /// Only campaigns in this state; null = every campaign.
  final CampaignState? filter;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminCampaignListState copyWith({
    LoadStatus? status,
    List<AdminCampaign>? campaigns,
    CampaignState? Function()? filter,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminCampaignListState(
    status: status ?? this.status,
    campaigns: campaigns ?? this.campaigns,
    filter: filter != null ? filter() : this.filter,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    campaigns,
    filter,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// Every campaign, newest first, with a state filter and "load more" paging.
@injectable
class AdminCampaignListCubit extends Cubit<AdminCampaignListState> {
  AdminCampaignListCubit(this._repository)
    : super(const AdminCampaignListState());

  static const pageSize = 20;

  final AdminCampaignsRepository _repository;
  int _page = 1;
  int _generation = 0;

  /// First page for the current filter. Campaigns already on screen stay until
  /// the new page arrives.
  Future<void> load() async {
    final generation = ++_generation;
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final result = await _repository.getCampaigns(
      status: state.filter,
      page: 1,
      pageSize: pageSize,
    );
    // A newer filter has its own request in flight.
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminCampaign>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            campaigns: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminCampaign>>(:final failure):
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
    final result = await _repository.getCampaigns(
      status: state.filter,
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok<List<AdminCampaign>>(:final value):
        _page++;
        emit(
          state.copyWith(
            campaigns: [...state.campaigns, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminCampaign>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> setFilter(CampaignState? filter) {
    if (filter == state.filter) return Future.value();
    emit(state.copyWith(filter: () => filter));
    return load();
  }
}
