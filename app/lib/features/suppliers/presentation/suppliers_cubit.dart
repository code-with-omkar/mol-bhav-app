import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/suppliers.dart';

class SuppliersState extends Equatable {
  const SuppliersState({
    this.status = LoadStatus.initial,
    this.suppliers = const [],
    this.search = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<Supplier> suppliers;
  final String search;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  SuppliersState copyWith({
    LoadStatus? status,
    List<Supplier>? suppliers,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => SuppliersState(
    status: status ?? this.status,
    suppliers: suppliers ?? this.suppliers,
    search: search ?? this.search,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    suppliers,
    search,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// The supplier directory: search by name, "load more" paging.
@injectable
class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this._repository) : super(const SuppliersState());

  static const pageSize = 30;

  final SuppliersRepository _repository;
  int _page = 1;

  /// First page for [search] (the current search when omitted). Suppliers
  /// already on screen stay until the new page arrives.
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
    final result = await _repository.getSuppliers(
      page: 1,
      pageSize: pageSize,
      search: term,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<Supplier>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            suppliers: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<Supplier>>(:final failure):
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
    final result = await _repository.getSuppliers(
      page: _page + 1,
      pageSize: pageSize,
      search: state.search,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<Supplier>>(:final value):
        _page++;
        emit(
          state.copyWith(
            suppliers: [...state.suppliers, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<Supplier>>():
        // Keep what is shown; asking again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }
}
