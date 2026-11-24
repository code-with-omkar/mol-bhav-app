import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_mandis.dart';
import '../domain/admin_suppliers.dart';

class AdminSuppliersState extends Equatable {
  const AdminSuppliersState({
    this.status = LoadStatus.initial,
    this.suppliers = const [],
    this.search = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminSupplier> suppliers;
  final String search;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminSuppliersState copyWith({
    LoadStatus? status,
    List<AdminSupplier>? suppliers,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminSuppliersState(
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

/// The suppliers and hubs: search, "load more" paging, add, edit, show or hide.
@injectable
class AdminSuppliersCubit extends Cubit<AdminSuppliersState> {
  AdminSuppliersCubit(this._repository, this._mandis)
    : super(const AdminSuppliersState());

  static const pageSize = 30;

  final AdminSuppliersRepository _repository;
  final AdminMandisRepository _mandis;
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
      case Ok<List<AdminSupplier>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            suppliers: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminSupplier>>(:final failure):
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
      case Ok<List<AdminSupplier>>(:final value):
        _page++;
        emit(
          state.copyWith(
            suppliers: [...state.suppliers, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminSupplier>>():
        // Keep what is shown; asking again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// The districts a supplier can sit in.
  Future<Result<List<DistrictChoice>>> districts() => _mandis.getDistricts();

  /// Adds a supplier; null on success (the list is reread), else why not.
  Future<Failure?> create({
    required String code,
    required String name,
    required String districtId,
    String? contactPhone,
  }) => _then(
    () => _repository.createSupplier(
      code: code,
      name: name,
      districtId: districtId,
      contactPhone: contactPhone,
    ),
  );

  /// Saves a supplier; null on success (the list is reread), else why not.
  Future<Failure?> update({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
    String? contactPhone,
  }) => _then(
    () => _repository.updateSupplier(
      id: id,
      name: name,
      districtId: districtId,
      isActive: isActive,
      contactPhone: contactPhone,
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
