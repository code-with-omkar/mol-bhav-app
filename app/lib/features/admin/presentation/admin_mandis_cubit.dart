import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_mandis.dart';

class AdminMandisState extends Equatable {
  const AdminMandisState({
    this.status = LoadStatus.initial,
    this.mandis = const [],
    this.search = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminMandi> mandis;
  final String search;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminMandisState copyWith({
    LoadStatus? status,
    List<AdminMandi>? mandis,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminMandisState(
    status: status ?? this.status,
    mandis: mandis ?? this.mandis,
    search: search ?? this.search,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    mandis,
    search,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// The mandis: search, "load more" paging, add, rename, move, show or hide.
@injectable
class AdminMandisCubit extends Cubit<AdminMandisState> {
  AdminMandisCubit(this._repository) : super(const AdminMandisState());

  static const pageSize = 30;

  final AdminMandisRepository _repository;
  int _page = 1;

  /// First page for [search] (the current search when omitted). Mandis already
  /// on screen stay until the new page arrives.
  Future<void> load({String? search}) async {
    final term = (search ?? state.search).trim();
    _page = 1;
    emit(
      state.copyWith(
        status: LoadStatus.loading,
        search: term,
        failure: () => null,
      ),
    );
    final result = await _repository.getMandis(
      page: 1,
      pageSize: pageSize,
      search: term,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminMandi>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            mandis: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminMandi>>(:final failure):
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
    final result = await _repository.getMandis(
      page: _page + 1,
      pageSize: pageSize,
      search: state.search,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminMandi>>(:final value):
        _page++;
        emit(
          state.copyWith(
            mandis: [...state.mandis, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminMandi>>():
        // Keep what is shown; asking again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// The districts a mandi can sit in.
  Future<Result<List<DistrictChoice>>> districts() =>
      _repository.getDistricts();

  /// Adds a mandi; null on success (the list is reread), else why not.
  Future<Failure?> create({
    required String code,
    required String name,
    required String districtId,
  }) => _then(
    () =>
        _repository.createMandi(code: code, name: name, districtId: districtId),
  );

  /// Saves a mandi's name, district and on/off; null on success, else why not.
  Future<Failure?> update({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
  }) => _then(
    () => _repository.updateMandi(
      id: id,
      name: name,
      districtId: districtId,
      isActive: isActive,
    ),
  );

  Future<Failure?> _then(Future<Result<void>> Function() save) async {
    final result = await save();
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
