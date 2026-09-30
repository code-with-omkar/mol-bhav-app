import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

enum AlertKind { signal, opportunity, spike }

enum AlertFilter { all, signals, opportunities }

enum AlertChannel { whatsapp, push }

enum PriceCondition { below, above, percent }

class AlertItem extends Equatable {
  const AlertItem({
    required this.id,
    required this.kind,
    required this.isUnread,
    required this.productName,
    required this.percentChange,
    required this.previousPrice,
    required this.newPrice,
    required this.createdAt,
    this.locationName,
    this.channel,
    this.opportunityId,
  });

  final String id;
  final AlertKind kind;
  final bool isUnread;

  /// The parts the alert's line is built from — the wording itself is
  /// localised on the page, not written here.
  final String productName;

  /// Signed: negative for a drop, positive for a rise.
  final num percentChange;
  final num previousPrice;
  final num newPrice;

  /// Empty when the API sent no mandi/supplier name for the alert.
  final String? locationName;
  final DateTime createdAt;
  final AlertChannel? channel;

  /// Present when the alert links to a buying opportunity.
  final String? opportunityId;

  @override
  List<Object?> get props => [
    id,
    kind,
    isUnread,
    productName,
    percentChange,
    previousPrice,
    newPrice,
    locationName,
    createdAt,
    channel,
    opportunityId,
  ];
}

class AlertProduct extends Equatable {
  const AlertProduct({
    required this.id,
    required this.name,
    required this.categoryCode,
    required this.unit,
  });

  final String id;
  final String name;
  final String categoryCode;
  final String unit;

  @override
  List<Object?> get props => [id, name, categoryCode, unit];
}

class AlertMarket extends Equatable {
  const AlertMarket({
    required this.id,
    required this.name,
    required this.stateName,
  });

  final String id;
  final String name;

  /// The mandi's state, so the form can show the user's own state first.
  final String stateName;

  @override
  List<Object?> get props => [id, name, stateName];
}

/// Reference data for the Create Alert form.
class AlertOptions extends Equatable {
  const AlertOptions({
    required this.products,
    required this.markets,
    this.whatsappNumber,
    this.whatsappLanguage,
  });

  final List<AlertProduct> products;
  final List<AlertMarket> markets;

  /// Number and language code WhatsApp alerts go to.
  final String? whatsappNumber;
  final String? whatsappLanguage;

  @override
  List<Object?> get props => [
    products,
    markets,
    whatsappNumber,
    whatsappLanguage,
  ];
}

class CurrentPrice extends Equatable {
  const CurrentPrice({
    required this.marketName,
    required this.price,
    required this.unit,
  });

  final String marketName;
  final num price;
  final String unit;

  @override
  List<Object?> get props => [marketName, price, unit];
}

class NewAlert extends Equatable {
  const NewAlert({
    required this.commodityId,
    required this.marketId,
    required this.condition,
    required this.value,
    required this.push,
    required this.whatsapp,
  });

  final String commodityId;
  final String marketId;
  final PriceCondition condition;

  /// Rupees for below/above, percent for [PriceCondition.percent].
  final num value;
  final bool push;
  final bool whatsapp;

  @override
  List<Object?> get props => [
    commodityId,
    marketId,
    condition,
    value,
    push,
    whatsapp,
  ];
}

enum AlertThresholdType { priceDrop, priceSpike, priceBelow, priceAbove }

class AlertRule extends Equatable {
  const AlertRule({
    required this.id,
    required this.productName,
    this.variantName,
    this.locationName,
    required this.thresholdType,
    this.thresholdPercent,
    this.thresholdPrice,
    required this.unit,
    required this.isActive,
    required this.createdAtUtc,
  });

  final String id;
  final String productName;
  final String? variantName;
  final String? locationName;
  final AlertThresholdType thresholdType;
  final num? thresholdPercent;
  final num? thresholdPrice;
  final String unit;
  final bool isActive;
  final DateTime createdAtUtc;

  @override
  List<Object?> get props => [
    id,
    productName,
    variantName,
    locationName,
    thresholdType,
    thresholdPercent,
    thresholdPrice,
    unit,
    isActive,
    createdAtUtc,
  ];
}

class UpdateAlertRuleRequest {
  const UpdateAlertRuleRequest({
    required this.thresholdType,
    this.thresholdPercent,
    this.thresholdPrice,
    required this.isActive,
  });

  final AlertThresholdType thresholdType;
  final num? thresholdPercent;
  final num? thresholdPrice;
  final bool isActive;
}

abstract interface class AlertsRepository {
  Future<Result<List<AlertItem>>> getAlerts(AlertFilter filter);

  Future<Result<AlertOptions>> getOptions();

  Future<Result<CurrentPrice>> getCurrentPrice(
    String commodityId,
    String marketId,
  );

  Future<Result<void>> create(NewAlert alert);

  Future<Result<List<AlertRule>>> getAlertRules();

  Future<Result<void>> updateAlertRule(String id, UpdateAlertRuleRequest req);

  Future<Result<void>> deleteAlertRule(String id);
}

@injectable
class GetAlerts {
  const GetAlerts(this._repository);

  final AlertsRepository _repository;

  Future<Result<List<AlertItem>>> call(AlertFilter filter) =>
      _repository.getAlerts(filter);
}

@injectable
class GetAlertOptions {
  const GetAlertOptions(this._repository);

  final AlertsRepository _repository;

  Future<Result<AlertOptions>> call() => _repository.getOptions();
}

@injectable
class GetCurrentPrice {
  const GetCurrentPrice(this._repository);

  final AlertsRepository _repository;

  Future<Result<CurrentPrice>> call(String commodityId, String marketId) =>
      _repository.getCurrentPrice(commodityId, marketId);
}

@injectable
class CreateAlert {
  const CreateAlert(this._repository);

  final AlertsRepository _repository;

  Future<Result<void>> call(NewAlert alert) => _repository.create(alert);
}
