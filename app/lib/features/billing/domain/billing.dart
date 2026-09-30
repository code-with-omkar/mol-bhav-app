import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// One plan row is one price for one cycle; the plan code identifies both.
enum BillingCycle { monthly, yearly }

enum SubscriptionStatus { active, cancelled, expired, pendingPayment }

class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.code,
    required this.name,
    required this.pricePaise,
    required this.currency,
    required this.cycle,
  });

  final String id;
  final String code;
  final String name;
  final int pricePaise;
  final String currency;
  final BillingCycle cycle;

  @override
  List<Object?> get props => [id, code, name, pricePaise, currency, cycle];
}

/// What `POST /billing/subscribe` hands back to open checkout. [isStub] means
/// the server has no real gateway (Development): there is nothing to pay.
class SubscribeResponse extends Equatable {
  const SubscribeResponse({
    required this.subscriptionId,
    required this.gatewayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
    required this.planName,
    required this.cycle,
    required this.isStub,
  });

  final String subscriptionId;
  final String gatewayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;
  final String planName;
  final BillingCycle cycle;
  final bool isStub;

  @override
  List<Object?> get props => [
    subscriptionId,
    gatewayOrderId,
    amountPaise,
    currency,
    keyId,
    planName,
    cycle,
    isStub,
  ];
}

class CouponValidation extends Equatable {
  const CouponValidation({
    required this.isValid,
    required this.originalAmountPaise,
    required this.discountPaise,
    required this.finalAmountPaise,
  });

  final bool isValid;
  final int originalAmountPaise;
  final int discountPaise;
  final int finalAmountPaise;

  @override
  List<Object?> get props => [
    isValid,
    originalAmountPaise,
    discountPaise,
    finalAmountPaise,
  ];
}

class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.planCode,
    required this.planName,
    required this.status,
    required this.cycle,
    required this.expiresAt,
  });

  final String id;
  final String planCode;
  final String planName;
  final SubscriptionStatus status;
  final BillingCycle cycle;
  final DateTime expiresAt;

  bool get isActive => status == SubscriptionStatus.active;

  @override
  List<Object?> get props => [id, planCode, planName, status, cycle, expiresAt];
}

abstract interface class BillingRepository {
  /// Cached plans first, then the live list.
  Stream<Result<List<Plan>>> watchPlans();

  Future<Result<SubscribeResponse>> subscribe(
    String planCode, {
    String? couponCode,
  });

  Future<Result<CouponValidation>> validateCoupon(String code, String planCode);

  /// Cached first, then live; `null` when the user has never subscribed.
  Stream<Result<Subscription?>> watchCurrentSubscription();

  Future<Result<void>> cancelSubscription();

  Future<Result<Subscription>> activateSubscription({
    required String orderId,
    required String paymentId,
    required String signature,
  });
}
