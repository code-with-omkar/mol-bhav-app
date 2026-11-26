import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../account/presentation/profile_cubit.dart';
import '../domain/alerts.dart';

class AlertsState extends Equatable {
  const AlertsState({
    this.filter = AlertFilter.all,
    this.data = const DataState(),
  });

  final AlertFilter filter;

  /// Every alert and opportunity; the tabs filter it on the device, so
  /// switching tabs is instant and never refetches.
  final DataState<List<AlertItem>> data;

  /// The items for the selected tab, or null while nothing is loaded.
  List<AlertItem>? get visible {
    final all = data.data;
    return all == null ? null : applyFilter(all, filter);
  }

  int count(AlertFilter f) => applyFilter(data.data ?? const [], f).length;

  static List<AlertItem> applyFilter(List<AlertItem> items, AlertFilter f) =>
      switch (f) {
        AlertFilter.all => items,
        AlertFilter.signals => [
          for (final a in items)
            if (a.kind != AlertKind.opportunity) a,
        ],
        AlertFilter.opportunities => [
          for (final a in items)
            if (a.kind == AlertKind.opportunity) a,
        ],
      };

  @override
  List<Object?> get props => [filter, data];
}

@injectable
class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit(this._getAlerts) : super(const AlertsState());

  final GetAlerts _getAlerts;

  Future<void> load() async {
    emit(
      AlertsState(
        filter: state.filter,
        data: DataState.loading(data: state.data.data),
      ),
    );
    // Saved alerts show at once; the live list replaces them when it lands.
    await for (final result in _getAlerts(AlertFilter.all)) {
      if (isClosed) return;
      emit(
        AlertsState(filter: state.filter, data: DataState.fromResult(result)),
      );
    }
  }

  /// Only changes what is shown: the full list is already loaded.
  void selectFilter(AlertFilter filter) {
    if (filter == state.filter) return;
    emit(AlertsState(filter: filter, data: state.data));
  }
}

class CreateAlertState extends Equatable {
  const CreateAlertState({
    this.options = const DataState(),
    this.categoryCodes = const [],
    this.stateId,
    this.markets = const [],
    this.loadingMarkets = false,
    this.productId,
    this.marketId,
    this.condition = PriceCondition.below,
    this.valueText = '',
    this.push = true,
    this.whatsapp = true,
    this.currentPrice,
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
  });

  final DataState<AlertOptions> options;

  /// The user's procurement categories; empty shows every product.
  final List<String> categoryCodes;

  /// The state whose markets are offered; the user's own one to begin with.
  final String? stateId;
  final List<AlertMarket> markets;
  final bool loadingMarkets;
  final String? productId;
  final String? marketId;
  final PriceCondition condition;
  final String valueText;
  final bool push;
  final bool whatsapp;
  final CurrentPrice? currentPrice;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  num? get value {
    final parsed = num.tryParse(valueText.replaceAll(',', ''));
    return parsed != null && parsed > 0 ? parsed : null;
  }

  /// Products of the user's categories, or all of them when they have none.
  List<AlertProduct> get products {
    final all = options.data?.products ?? const <AlertProduct>[];
    if (categoryCodes.isEmpty) return all;
    final mine = [
      for (final p in all)
        if (categoryCodes.contains(p.categoryCode)) p,
    ];
    return mine.isEmpty ? all : mine;
  }

  AlertProduct? get product =>
      options.data?.products.where((p) => p.id == productId).firstOrNull;

  bool get canSubmit =>
      productId != null &&
      marketId != null &&
      value != null &&
      (push || whatsapp) &&
      submitStatus != SubmitStatus.submitting;

  CreateAlertState copyWith({
    DataState<AlertOptions>? options,
    List<String>? categoryCodes,
    String? stateId,
    List<AlertMarket>? markets,
    bool? loadingMarkets,
    String? productId,
    ValueGetter<String?>? marketId,
    PriceCondition? condition,
    String? valueText,
    bool? push,
    bool? whatsapp,
    ValueGetter<CurrentPrice?>? currentPrice,
    SubmitStatus? submitStatus,
    Failure? submitFailure,
  }) => CreateAlertState(
    options: options ?? this.options,
    categoryCodes: categoryCodes ?? this.categoryCodes,
    stateId: stateId ?? this.stateId,
    markets: markets ?? this.markets,
    loadingMarkets: loadingMarkets ?? this.loadingMarkets,
    productId: productId ?? this.productId,
    marketId: marketId != null ? marketId() : this.marketId,
    condition: condition ?? this.condition,
    valueText: valueText ?? this.valueText,
    push: push ?? this.push,
    whatsapp: whatsapp ?? this.whatsapp,
    currentPrice: currentPrice != null ? currentPrice() : this.currentPrice,
    submitStatus: submitStatus ?? SubmitStatus.idle,
    submitFailure: submitFailure,
  );

  @override
  List<Object?> get props => [
    options,
    categoryCodes,
    stateId,
    markets,
    loadingMarkets,
    productId,
    marketId,
    condition,
    valueText,
    push,
    whatsapp,
    currentPrice,
    submitStatus,
    submitFailure,
  ];
}

@injectable
class CreateAlertCubit extends Cubit<CreateAlertState> {
  CreateAlertCubit(
    this._getOptions,
    this._getMarkets,
    this._getCurrentPrice,
    this._createAlert,
    this._profile,
  ) : super(const CreateAlertState());

  final GetAlertOptions _getOptions;
  final GetAlertMarkets _getMarkets;
  final GetCurrentPrice _getCurrentPrice;
  final CreateAlert _createAlert;
  final ProfileCubit _profile;

  /// Loads the form, preselecting [commodityId] / [marketId] when given —
  /// they come from the comparison, trends and watchlist rows.
  Future<void> load({String? commodityId, String? marketId}) async {
    emit(state.copyWith(options: const DataState.loading()));
    await _profile.ensureLoaded();
    final result = await _getOptions();
    if (isClosed) return;
    final profile = _profile.state.data;
    final narrowed = state.copyWith(
      options: DataState.fromResult(result),
      categoryCodes: profile?.categoryCodes ?? const [],
    );
    final productId =
        narrowed.products.where((p) => p.id == commodityId).firstOrNull?.id ??
        narrowed.products.firstOrNull?.id;
    emit(narrowed.copyWith(productId: productId));

    final states = narrowed.options.data?.states ?? const <AlertState>[];
    // A market passed in may sit outside the user's state: open on its state
    // so the choice made on the previous screen is kept.
    String? passedState;
    if (marketId != null && productId != null) {
      final price = await _getCurrentPrice(productId, marketId);
      if (isClosed) return;
      passedState = price.fold((_) => null, (p) => p.stateName);
    }
    final home =
        states.where((s) => s.name == passedState).firstOrNull ??
        states.where((s) => s.id == profile?.stateId).firstOrNull ??
        states.where((s) => s.name == profile?.stateName).firstOrNull ??
        states.firstOrNull;
    if (home == null) return;
    await _loadMarkets(home.id, preferred: marketId);
  }

  Future<void> selectProduct(String id) async {
    emit(state.copyWith(productId: id, currentPrice: () => null));
    await _refreshPrice();
  }

  Future<void> selectMarket(String id) async {
    emit(state.copyWith(marketId: () => id, currentPrice: () => null));
    await _refreshPrice();
  }

  /// Offers the markets of another state and picks its first one.
  Future<void> selectState(String id) async {
    if (id == state.stateId) return;
    await _loadMarkets(id);
  }

  Future<void> _loadMarkets(String stateId, {String? preferred}) async {
    emit(
      state.copyWith(
        stateId: stateId,
        markets: const [],
        loadingMarkets: true,
        marketId: () => null,
        currentPrice: () => null,
      ),
    );
    final result = await _getMarkets(stateId);
    // A newer choice of state wins over a slow earlier one.
    if (isClosed || state.stateId != stateId) return;
    final markets = result.fold((_) => const <AlertMarket>[], (m) => m);
    final chosen =
        markets.where((m) => m.id == preferred).firstOrNull ??
        markets.firstOrNull;
    emit(
      state.copyWith(
        markets: markets,
        loadingMarkets: false,
        marketId: () => chosen?.id,
        submitStatus: result.fold((_) => SubmitStatus.failure, (_) => null),
        submitFailure: result.fold((f) => f, (_) => null),
      ),
    );
    await _refreshPrice();
  }

  void selectCondition(PriceCondition condition) =>
      emit(state.copyWith(condition: condition));

  void valueChanged(String text) => emit(state.copyWith(valueText: text));

  void togglePush(bool on) => emit(state.copyWith(push: on));

  void toggleWhatsapp(bool on) => emit(state.copyWith(whatsapp: on));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _createAlert(
      NewAlert(
        commodityId: state.productId!,
        marketId: state.marketId!,
        condition: state.condition,
        value: state.value!,
        push: state.push,
        whatsapp: state.whatsapp,
      ),
    );
    emit(
      result.fold(
        (f) => state.copyWith(
          submitStatus: SubmitStatus.failure,
          submitFailure: f,
        ),
        (_) => state.copyWith(submitStatus: SubmitStatus.success),
      ),
    );
  }

  /// The helper line is best-effort: a failure just hides it.
  Future<void> _refreshPrice() async {
    final productId = state.productId, marketId = state.marketId;
    if (productId == null || marketId == null) return;
    final result = await _getCurrentPrice(productId, marketId);
    if (isClosed ||
        state.productId != productId ||
        state.marketId != marketId) {
      return;
    }
    emit(
      state.copyWith(currentPrice: () => result.fold((_) => null, (p) => p)),
    );
  }
}
