import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/locale/locale_cubit.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../account/domain/account.dart';
import '../../account/presentation/profile_cubit.dart';
import '../../catalog/domain/catalog.dart';
import '../../opportunities/domain/opportunities.dart';
import '../../watchlist/domain/watchlist.dart';
import '../../watchlist/presentation/watchlist_cubit.dart';
import '../domain/home_entities.dart';
import 'home_prefetcher.dart';

/// Home = the shared profile + the shared watchlist + the user's categories.
/// Rebuilds whenever either shared cubit changes, so an edited profile or a
/// starred product shows here without a manual refresh.
@injectable
class HomeCubit extends Cubit<DataState<HomeDashboard>> {
  HomeCubit(
    this._profile,
    this._watchlist,
    this._catalog,
    this._opportunities,
    LocaleCubit locale, [
    this._prefetcher,
  ]) : super(const DataState()) {
    _subs = [
      _profile.stream.listen((_) => _onProfile()),
      _watchlist.stream.listen((_) => _rebuild()),
      // Category names are localised by the API.
      locale.stream.listen((_) => _loadCategories()),
    ];
  }

  static const _previewSize = 5;

  /// Opportunities in the Home slider.
  static const maxTopOpportunities = 5;

  /// An opportunity older than this is no longer shown on Home.
  static const _opportunityShelfLife = Duration(days: 3);

  final ProfileCubit _profile;
  final WatchlistCubit _watchlist;
  final CatalogRepository _catalog;
  final OpportunitiesRepository _opportunities;
  final HomePrefetcher? _prefetcher;
  List<MarketOpportunity> _recentOpportunities = const [];
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
      _loadOpportunities(),
    ]);
    // Home is on screen: warm the cache for the tabs opened next.
    _prefetcher?.warm();
  }

  /// Pull-to-refresh: everything from the API again.
  Future<void> refresh() async {
    await Future.wait([
      _profile.load(),
      _watchlist.load(),
      _loadCategories(),
      _loadOpportunities(),
    ]);
  }

  /// Best effort: Home works the same without opportunities.
  Future<void> _loadOpportunities() async {
    final result = await _opportunities.getRecent();
    if (isClosed) return;
    if (result case Ok(:final value)) {
      _recentOpportunities = value;
      _rebuild();
    }
  }

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
    final dashboard = _dashboard(
      profile,
      categories,
      _watchlist.state.items,
      _recentOpportunities,
    );
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
    List<MarketOpportunity> opportunities,
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
      topOpportunities: topOpportunities(opportunities, watchlist),
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

  /// Recent opportunities for products still on the watchlist: the newest
  /// one per product, biggest saving first, at most [maxTopOpportunities].
  @visibleForTesting
  static List<TopOpportunity> topOpportunities(
    List<MarketOpportunity> opportunities,
    List<WatchlistItem> watchlist, {
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(_opportunityShelfLife);
    final newestFirst = [...opportunities]
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    final seen = <String>{};
    final picked = <(MarketOpportunity, WatchlistItem)>[];
    for (final o in newestFirst) {
      if (o.detectedAt.isBefore(cutoff) || !seen.add(o.productId)) continue;
      final watched = watchlist
          .where((w) => w.commodityId == o.productId)
          .firstOrNull;
      if (watched == null) continue;
      picked.add((o, watched));
    }
    picked.sort((a, b) => b.$1.savingsPercent.compareTo(a.$1.savingsPercent));
    return [
      for (final (o, watched) in picked.take(maxTopOpportunities))
        TopOpportunity(
          commodityId: o.productId,
          product: o.displayName,
          categoryCode: watched.categoryCode,
          priceSource: o.bestDistrict,
          updatedAt: o.priceDate,
          price: o.bestPrice,
          unit: o.unit,
          change: -o.savingsPerUnit,
          percent: -o.savingsPercent.toDouble(),
          trend: const [],
          bestMarketName: o.bestName,
          opportunityId: o.id,
          referenceMarketName: o.homeName,
          savingsPercent: o.savingsPercent,
        ),
    ];
  }

  @override
  Future<void> close() {
    for (final sub in _subs) {
      sub.cancel();
    }
    return super.close();
  }
}
