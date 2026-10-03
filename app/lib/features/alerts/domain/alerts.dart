import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';

/// Tabs on the alerts feed.
enum AlertFilter { all, signals, opportunities }

/// What raised an alert: a price drop/below-threshold signal, a spike, or a
/// procurement opportunity.
enum AlertKind { signal, spike, opportunity }

/// The channel an alert was delivered on, when known.
enum AlertChannel { whatsapp, push }

/// The Create Alert form's condition. Rupee conditions are price-level rules;
/// [percent] is a "changes by %" rule.
enum PriceCondition { below, above, percent }

/// Server-side rule threshold, mirrored 1:1 from the API's `thresholdType`.
enum AlertThresholdType { priceDrop, priceSpike, priceBelow, priceAbove }

class AlertItem extends Equatable {
  const AlertItem({
    required this.id,
    required this.kind,
    required this.productName,
    required this.percentChange,
    required this.previousPrice,
    required this.newPrice,
    required this.createdAt,
    required this.isUnread,
    this.locationName,
    this.opportunityId,
    this.channel,
  });

  final String id;
  final AlertKind kind;
  final String productName;
  final num percentChange;
  final num previousPrice;
  final num newPrice;
  final DateTime createdAt;
  final bool isUnread;
  final String? locationName;
  final String? opportunityId;
  final AlertChannel? channel;

  @override
  List<Object?> get props => [
    id,
    kind,
    productName,
    percentChange,
    previousPrice,
    newPrice,
    createdAt,
    isUnread,
    locationName,
    opportunityId,
    channel,
  ];
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

  /// Rupees for [PriceCondition.below]/[PriceCondition.above], percent for
  /// [PriceCondition.percent].
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

  /// Display symbol of the product's default unit, e.g. `qtl`.
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

  /// Empty when the mandi master has no state for it.
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

  /// Where WhatsApp alerts go; null hides the subtitle on the toggle.
  final String? whatsappNumber;

  /// Language code WhatsApp alerts are sent in.
  final String? whatsappLanguage;

  @override
  List<Object?> get props => [
    products,
    markets,
    whatsappNumber,
    whatsappLanguage,
  ];
}

/// Latest modal price for a product at the selected mandi — the form's hint.
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

class AlertRule extends Equatable {
  const AlertRule({
    required this.id,
    required this.productName,
    required this.thresholdType,
    required this.unit,
    required this.isActive,
    required this.createdAtUtc,
    this.variantName,
    this.locationName,
    this.thresholdPercent,
    this.thresholdPrice,
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

class UpdateAlertRuleRequest extends Equatable {
  const UpdateAlertRuleRequest({
    required this.thresholdType,
    required this.isActive,
    this.thresholdPercent,
    this.thresholdPrice,
  });

  final AlertThresholdType thresholdType;
  final num? thresholdPercent;
  final num? thresholdPrice;
  final bool isActive;

  @override
  List<Object?> get props => [
    thresholdType,
    thresholdPercent,
    thresholdPrice,
    isActive,
  ];
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
