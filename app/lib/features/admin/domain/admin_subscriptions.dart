import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Where a subscription stands (the API's `SubscriptionStatus`).
enum SubscriptionState {
  active('Active'),
  pendingPayment('PendingPayment'),
  cancelled('Cancelled'),
  expired('Expired');

  const SubscriptionState(this.wire);

  final String wire;

  /// A state this build does not know reads as [expired], which grants nothing.
  static SubscriptionState fromWire(String value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => expired);
}

/// One purchase of a plan (`GET /admin/billing/subscriptions`). The API names
/// its owner only by a masked phone number and, if set, their name.
class AdminSubscription extends Equatable {
  const AdminSubscription({
    required this.id,
    required this.userId,
    required this.planCode,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.isAutoRenew,
    this.cancelledAt,
    this.userPhone,
    this.userName,
  });

  final String id;
  final String userId;
  final String planCode;
  final SubscriptionState status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isAutoRenew;
  final DateTime? cancelledAt;

  /// Masked, e.g. `******3210`; null when the account no longer exists.
  final String? userPhone;
  final String? userName;

  /// What to call the owner in a list: their name, else the masked number.
  String? get userLabel => userName ?? userPhone;

  /// Only an active subscription can be ended early.
  bool get canEnd => status == SubscriptionState.active;

  @override
  List<Object?> get props => [
    id,
    userId,
    planCode,
    status,
    startedAt,
    expiresAt,
    isAutoRenew,
    cancelledAt,
    userPhone,
    userName,
  ];
}

abstract interface class AdminSubscriptionsRepository {
  /// Newest first; [status] narrows them, null = all.
  Future<Result<List<AdminSubscription>>> getSubscriptions({
    SubscriptionState? status,
    required int page,
    required int pageSize,
  });

  /// Ends an active subscription now; the owner goes back to the free plan.
  Future<Result<void>> expire(String subscriptionId);
}
