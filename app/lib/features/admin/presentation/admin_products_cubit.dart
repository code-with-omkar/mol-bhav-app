import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_commodities.dart';
import '../domain/admin_products.dart';

class AdminProductsState extends Equatable {
  const AdminProductsState({
    this.status = LoadStatus.initial,
    this.products = const [],
    this.search = '',
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminProductSummary> products;
  final String search;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminProductsState copyWith({
    LoadStatus? status,
    List<AdminProductSummary>? products,
    String? search,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminProductsState(
    status: status ?? this.status,
    products: products ?? this.products,
    search: search ?? this.search,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    products,
    search,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// The catalog's products: search, "load more" paging, and editing names and
/// on/off.
@injectable
class AdminProductsCubit extends Cubit<AdminProductsState> {
  AdminProductsCubit(this._repository, this._commodities)
    : super(const AdminProductsState());

  static const pageSize = 30;

  final AdminProductsRepository _repository;
  final AdminCommoditiesRepository _commodities;
  int _page = 1;

  /// First page for [search] (the current search when omitted). Products
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
    final result = await _repository.getProducts(
      page: 1,
      pageSize: pageSize,
      search: term,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminProductSummary>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            products: value,
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminProductSummary>>(:final failure):
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
    final result = await _repository.getProducts(
      page: _page + 1,
      pageSize: pageSize,
      search: state.search,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminProductSummary>>(:final value):
        _page++;
        emit(
          state.copyWith(
            products: [...state.products, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminProductSummary>>():
        // Keep what is shown; asking again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// The sub-categories and units a new product can use.
  Future<Result<CommodityTargets>> targets() => _commodities.getTargets();

  /// Adds a product; null on success (the list is reread), else why not.
  Future<Failure?> create({
    required String code,
    required String subCategoryId,
    required String unitId,
    required Map<String, String> names,
  }) async {
    final result = await _repository.createProduct(
      code: code,
      subCategoryId: subCategoryId,
      unitId: unitId,
      names: names,
    );
    if (isClosed) return null;
    switch (result) {
      case Err<void>(:final failure):
        return failure;
      case Ok<void>():
        await load();
        return null;
    }
  }

  /// Adds a variant to a product; null on success, else why not.
  Future<Failure?> addVariant(
    String productId,
    String code,
    Map<String, String> names,
  ) async {
    final result = await _repository.addVariant(
      productId: productId,
      code: code,
      names: names,
    );
    return result.fold((failure) => failure, (_) => null);
  }

  /// Saves a variant's names and on/off; null on success, else why not.
  Future<Failure?> updateVariant(String productId, AdminVariant variant) async {
    final result = await _repository.updateVariant(
      productId: productId,
      variant: variant,
    );
    return result.fold((failure) => failure, (_) => null);
  }

  /// The whole product, to edit.
  Future<Result<AdminProduct>> detail(String id) => _repository.getProduct(id);

  /// Saves [product] (with its edited names and on/off); null on success (the
  /// list is reread), else why it failed.
  Future<Failure?> save(AdminProduct product) async {
    final result = await _repository.updateProduct(product);
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
