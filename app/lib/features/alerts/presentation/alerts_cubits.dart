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
  final DataState<List<AlertItem>> data;

  @override
  List<Object?> get props => [filter, data];
}

@injectable
class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit(this._getAlerts) : super(const AlertsState());

  final GetAlerts _getAlerts;

  Future<void> load() async {
    final filter = state.filter;
    emit(
      AlertsState(
        filter: filter,
        data: DataState.loading(data: state.data.data),
      ),
    );
    final result = await _getAlerts(filter);
    if (isClosed || state.filter != filter) return;
    emit(AlertsState(filter: filter, data: DataState.fromResult(result)));
  }

  Future<void> selectFilter(AlertFilter filter) {
    if (filter == state.filter) return Future.value();
    emit(AlertsState(filter: filter, data: state.data));
    return load();
  }
}

class CreateAlertState extends Equatable {
  const CreateAlertState({
    this.options = const DataState(),
    this.categoryCodes = const [],
    this.homeStateName,
    this.allStates = false,
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

  /// The user's own state, when the profile names one.
  final String? homeStateName;

  /// Lifts the mandi list out of [homeStateName].
  final bool allStates;
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

  /// Mandis in the user's state, unless they asked for all of them — or their
  /// state has none, in which case hiding every mandi would be worse.
  List<AlertMarket> get markets {
    final all = options.data?.markets ?? const <AlertMarket>[];
    final home = homeStateName;
    if (allStates || home == null) return all;
    final mine = [
      for (final m in all)
        if (m.stateName == home) m,
    ];
    return mine.isEmpty ? all : mine;
  }

  /// Whether an "all states" toggle is worth showing at all.
  bool get canWidenStates =>
      homeStateName != null &&
      markets.length != (options.data?.markets.length ?? 0);

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
    ValueGetter<String?>? homeStateName,
    bool? allStates,
    String? productId,
    String? marketId,
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
    homeStateName: homeStateName != null ? homeStateName() : this.homeStateName,
    allStates: allStates ?? this.allStates,
    productId: productId ?? this.productId,
    marketId: marketId ?? this.marketId,
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
    homeStateName,
    allStates,
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
    this._getCurrentPrice,
    this._createAlert,
    this._profile,
  ) : super(const CreateAlertState());

  final GetAlertOptions _getOptions;
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
      homeStateName: () =>
          profile?.stateName.isNotEmpty ?? false ? profile!.stateName : null,
    );
    // A mandi passed in may sit outside the user's state — widen rather than
    // drop the preselection they navigated in with.
    final market = narrowed.options.data?.markets
        .where((m) => m.id == marketId)
        .firstOrNull;
    final widened = market != null && !narrowed.markets.contains(market)
        ? narrowed.copyWith(allStates: true)
        : narrowed;
    emit(
      widened.copyWith(
        productId:
            widened.products
                .where((p) => p.id == commodityId)
                .firstOrNull
                ?.id ??
            widened.products.firstOrNull?.id,
        marketId: market?.id ?? widened.markets.firstOrNull?.id,
      ),
    );
    await _refreshPrice();
  }

  Future<void> selectProduct(String id) async {
    emit(state.copyWith(productId: id, currentPrice: () => null));
    await _refreshPrice();
  }

  Future<void> selectMarket(String id) async {
    emit(state.copyWith(marketId: id, currentPrice: () => null));
    await _refreshPrice();
  }

  /// Shows mandis outside the user's own state; the current pick survives.
  Future<void> toggleAllStates(bool on) async {
    final next = state.copyWith(allStates: on);
    if (next.markets.any((m) => m.id == next.marketId)) {
      emit(next);
      return;
    }
    emit(
      next.copyWith(
        marketId: next.markets.firstOrNull?.id,
        currentPrice: () => null,
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
