import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_billing.dart';

class AdminCouponsState extends Equatable {
  const AdminCouponsState({
    this.status = LoadStatus.initial,
    this.coupons = const [],
    this.plans = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.failure,
  });

  /// `loading` for the first page, `ready` once a page is in.
  final LoadStatus status;
  final List<AdminCoupon> coupons;

  /// The plans a coupon can be limited to.
  final List<AdminPlan> plans;

  /// The last page came back full, so another may follow.
  final bool hasMore;
  final bool loadingMore;
  final Failure? failure;

  AdminCouponsState copyWith({
    LoadStatus? status,
    List<AdminCoupon>? coupons,
    List<AdminPlan>? plans,
    bool? hasMore,
    bool? loadingMore,
    Failure? Function()? failure,
  }) => AdminCouponsState(
    status: status ?? this.status,
    coupons: coupons ?? this.coupons,
    plans: plans ?? this.plans,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    coupons,
    plans,
    hasMore,
    loadingMore,
    failure,
  ];
}

/// Discount codes, newest first, with "load more" paging; add one, or edit
/// an existing one's on/off, end date and use limit.
@injectable
class AdminCouponsCubit extends Cubit<AdminCouponsState> {
  AdminCouponsCubit(this._repository) : super(const AdminCouponsState());

  static const pageSize = 20;

  final AdminBillingRepository _repository;
  int _page = 1;

  /// First page, and the plans for the picker. Coupons already on screen stay
  /// until the new page arrives.
  Future<void> load() async {
    _page = 1;
    emit(state.copyWith(status: LoadStatus.loading, failure: () => null));
    final (coupons, plans) = await (
      _repository.getCoupons(page: 1, pageSize: pageSize),
      _repository.getPlans(),
    ).wait;
    if (isClosed) return;
    switch (coupons) {
      case Ok<List<AdminCoupon>>(:final value):
        emit(
          state.copyWith(
            status: LoadStatus.ready,
            coupons: value,
            // Without the plan list the picker only offers "any plan".
            plans: plans.fold((_) => state.plans, (list) => list),
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminCoupon>>(:final failure):
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
    final result = await _repository.getCoupons(
      page: _page + 1,
      pageSize: pageSize,
    );
    if (isClosed) return;
    switch (result) {
      case Ok<List<AdminCoupon>>(:final value):
        _page++;
        emit(
          state.copyWith(
            coupons: [...state.coupons, ...value],
            hasMore: value.length == pageSize,
            loadingMore: false,
          ),
        );
      case Err<List<AdminCoupon>>():
        // Keep what is shown; scrolling again retries.
        emit(state.copyWith(loadingMore: false));
    }
  }

  /// Adds a coupon; null on success (the list is reread), else why it failed.
  Future<Failure?> create(CouponDraft draft) =>
      _then(() => _repository.createCoupon(draft));

  /// Saves an edit; null on success, else why it failed.
  Future<Failure?> update(String id, CouponEdit edit) =>
      _then(() => _repository.updateCoupon(id, edit));

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
