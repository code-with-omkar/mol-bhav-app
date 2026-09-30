import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../account/domain/account.dart';
import '../../account/presentation/profile_cubit.dart';
import '../../catalog/domain/catalog.dart';
import '../../watchlist/domain/watchlist.dart';
import '../../watchlist/presentation/watchlist_cubit.dart';
import '../domain/home_entities.dart';

/// Home = the shared profile + the shared watchlist + the user's categories.
/// Rebuilds whenever either shared cubit changes, so an edited profile or a
/// starred product shows here without a manual refresh.
@injectable
class HomeCubit extends Cubit<DataState<HomeDashboard>> {
  HomeCubit(this._profile, this._watchlist, this._catalog, LocaleCubit locale)
    : super(const DataState()) {
    _subs = [
      _profile.stream.listen((_) => _onProfile()),
      _watchlist.stream.listen((_) => _rebuild()),
      // Category names are localised by the API.
      locale.stream.listen((_) => _loadCategories()),
    ];
  }

  static const _previewSize = 5;

  final ProfileCubit _profile;
  final WatchlistCubit _watchlist;
  final CatalogRepository _catalog;
  late final List<StreamSubscription<Object?>> _subs;

  List<CatalogCategory>? _categories;
  Failure? _categoriesFailure;
  bool _categoriesLoading = false;

  /// The profile's category codes when the categories were last loaded.
  List<String>? _loadedForCodes;

  Future<void> load() async {
    _rebuild();
    await Future.wait([
      _profile.ensureLoaded(),
      _watchlist.ensureLoaded(),
      if (_categories == null) _loadCategories(),
    ]);
  }

  /// Pull-to-refresh: everything from the API again.
  Future<void> refresh() =>
      Future.wait([_profile.load(), _watchlist.load(), _loadCategories()]);

  Future<void> retry() => refresh();

  void _onProfile() {
    final codes = _profile.state.data?.categoryCodes;
    // The user picked other categories: reload.
    if (codes != null &&
        _loadedForCodes != null &&
        !listEquals(codes, _loadedForCodes)) {
      _loadCategories();
    }
    _rebuild();
  }

  Future<void> _loadCategories() async {
    _categoriesLoading = true;
    _rebuild();
    final result = await _catalog.getCategories();
    if (isClosed) return;
    _categoriesLoading = false;
    _loadedForCodes = _profile.state.data?.categoryCodes;
    result.fold((f) => _categoriesFailure = f, (list) {
      _categories = list;
      _categoriesFailure = null;
    });
    _rebuild();
  }

  void _rebuild() {
    if (isClosed) return;
    final profileState = _profile.state;
    final profile = profileState.data;
    final categories = _categories;
    if (profile == null || categories == null) {
      final failure = profileState.failure ?? _categoriesFailure;
      final failed =
          profileState.status == LoadStatus.failure ||
          (!_categoriesLoading && _categoriesFailure != null);
      emit(
        failed && failure != null
            ? DataState(status: LoadStatus.failure, failure: failure)
            : const DataState.loading(),
      );
      return;
    }
    final dashboard = _dashboard(profile, categories, _watchlist.state.items);
    final revalidating =
        profileState.isLoading ||
        _watchlist.state.data.isLoading ||
        _categoriesLoading;
    emit(
      revalidating
          ? DataState.loading(data: dashboard)
          : DataState.ready(dashboard),
    );
  }

  static HomeDashboard _dashboard(
    AccountProfile profile,
    List<CatalogCategory> categories,
    List<WatchlistItem> watchlist,
  ) {
    final codes = profile.categoryCodes.toSet();
    return HomeDashboard(
      userName: profile.name,
      businessType: profile.businessTypeName,
      districtName: profile.districtName,
      stateName: profile.stateName,
      hasUnreadAlerts: false,
      categories: [
        for (final c in categories)
          if (codes.isEmpty || codes.contains(c.code))
            HomeCategory(code: c.code, name: c.name, highlights: const []),
      ],
      topOpportunity: null,
      watchlist: [
        for (final i in watchlist.take(_previewSize))
          WatchlistPreview(
            commodityId: i.commodityId,
            marketId: i.marketId,
            name: i.variety == null ? i.name : '${i.name} · ${i.variety}',
            categoryCode: i.categoryCode,
            price: i.price,
            unit: i.unit,
            percent: i.percent,
          ),
      ],
    );
  }

  @override
  Future<void> close() {
    for (final sub in _subs) {
      sub.cancel();
    }
    return super.close();
  }
}
