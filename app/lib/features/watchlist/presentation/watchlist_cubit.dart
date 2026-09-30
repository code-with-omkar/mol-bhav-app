import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/watchlist.dart';

class WatchlistState extends Equatable {
  const WatchlistState({
    this.data = const DataState(),
    this.category,
    this.query = '',
  });

  final DataState<Watchlist> data;

  /// Selected category code; `null` = All.
  final String? category;

  /// Local name filter from the search field.
  final String query;

  List<WatchlistItem> get items => data.data?.items ?? const [];

  List<WatchlistItem> get visibleItems {
    final q = query.trim().toLowerCase();
    return [
      for (final item in items)
        if ((category == null || item.categoryCode == category) &&
            (q.isEmpty ||
                item.name.toLowerCase().contains(q) ||
                (item.variety?.toLowerCase().contains(q) ?? false)))
          item,
    ];
  }

  /// The row watching exactly this product (and variant, when given).
  WatchlistItem? itemFor(String productId, {String? variantId}) => items
      .where((i) => i.commodityId == productId && i.variantId == variantId)
      .firstOrNull;

  WatchlistState copyWith({
    DataState<Watchlist>? data,
    String? Function()? category,
    String? query,
  }) => WatchlistState(
    data: data ?? this.data,
    category: category != null ? category() : this.category,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [data, category, query];
}

/// The watchlist shared by the Watchlist tab, the Home preview and every
/// star toggle, so a change anywhere shows everywhere at once. Cleared when
/// the session ends.
@lazySingleton
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._watch, this._add, this._remove, this._session)
    : super(const WatchlistState()) {
    _session.addListener(_onSession);
  }

  final WatchWatchlist _watch;
  final AddToWatchlist _add;
  final RemoveFromWatchlist _remove;
  final SessionManager _session;
  int _generation = 0;

  Future<void> load() async {
    if (!_session.hasSession) return;
    final generation = ++_generation;
    await for (final next in revalidate(_watch(), current: state.data.data)) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(data: next));
    }
  }

  Future<void> ensureLoaded() =>
      state.data.status == LoadStatus.initial ? load() : Future.value();

  void selectCategory(String? code) =>
      emit(state.copyWith(category: () => code));

  void search(String query) => emit(state.copyWith(query: query));

  /// Fails with [AlreadyWatchedFailure] for a duplicate.
  Future<Result<void>> add(String productId, {String? variantId}) async {
    final result = await _add(productId, variantId: variantId);
    final changed = switch (result) {
      Ok() => true,
      // Watched elsewhere since the last load: show it.
      Err(failure: AlreadyWatchedFailure()) => true,
      Err() => false,
    };
    if (changed) await load();
    return result;
  }

  /// Hides [item] at once, then deletes it; a failed delete brings it back.
  Future<Result<void>> remove(WatchlistItem item) async {
    final current = state.data.data;
    if (current != null) {
      emit(
        state.copyWith(
          data: DataState(
            status: state.data.status,
            data: Watchlist(
              categories: current.categories,
              items: [
                for (final i in current.items)
                  if (i.id != item.id) i,
              ],
              updatedAt: current.updatedAt,
            ),
          ),
        ),
      );
    }
    final result = await _remove(item.id);
    await load();
    return result;
  }

  /// Star buttons: removes the matching row, or adds the product/variant.
  Future<Result<void>> toggle(String productId, {String? variantId}) {
    final item = state.itemFor(productId, variantId: variantId);
    return item != null ? remove(item) : add(productId, variantId: variantId);
  }

  void _onSession() {
    if (_session.hasSession) return;
    _generation++;
    emit(const WatchlistState());
  }

  @override
  Future<void> close() {
    _session.removeListener(_onSession);
    return super.close();
  }
}
