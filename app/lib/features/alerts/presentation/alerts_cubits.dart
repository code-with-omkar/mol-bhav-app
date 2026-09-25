import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
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
  CreateAlertCubit(this._getOptions, this._getCurrentPrice, this._createAlert)
    : super(const CreateAlertState());

  final GetAlertOptions _getOptions;
  final GetCurrentPrice _getCurrentPrice;
  final CreateAlert _createAlert;

  /// Loads the form, preselecting [commodityId] / [marketId] when given.
  Future<void> load({String? commodityId, String? marketId}) async {
    emit(state.copyWith(options: const DataState.loading()));
    final result = await _getOptions();
    final options = DataState.fromResult(result);
    final data = options.data;
    emit(
      state.copyWith(
        options: options,
        productId:
            data?.products.where((p) => p.id == commodityId).firstOrNull?.id ??
            data?.products.firstOrNull?.id,
        marketId:
            data?.markets.where((m) => m.id == marketId).firstOrNull?.id ??
            data?.markets.firstOrNull?.id,
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
