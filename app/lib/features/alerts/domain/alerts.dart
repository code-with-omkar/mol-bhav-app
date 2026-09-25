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
    required this.title,
    required this.details,
    required this.createdAt,
    this.channel,
    this.opportunityId,
  });

  final String id;
  final AlertKind kind;
  final bool isUnread;

  /// Server-written, localised text: "Onion price dropped 8.2% in Nashik".
  final String title;
  final List<String> details;
  final DateTime createdAt;
  final AlertChannel? channel;

  /// Present when the alert links to a buying opportunity.
  final String? opportunityId;

  @override
  List<Object?> get props => [
    id,
    kind,
    isUnread,
    title,
    details,
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
  const AlertMarket({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
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

abstract interface class AlertsRepository {
  Future<Result<List<AlertItem>>> getAlerts(AlertFilter filter);

  Future<Result<AlertOptions>> getOptions();

  Future<Result<CurrentPrice>> getCurrentPrice(
    String commodityId,
    String marketId,
  );

  Future<Result<void>> create(NewAlert alert);
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
