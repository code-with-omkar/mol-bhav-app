import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/payments/razorpay_service.dart';
import '../../../../core/session/token_renewal.dart';
import '../../../account/presentation/profile_cubit.dart';
import '../../domain/billing.dart';

sealed class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

final class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

/// [subscription] is `null` for a user who has never subscribed.
final class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded(this.subscription);

  final Subscription? subscription;

  @override
  List<Object?> get props => [subscription];
}

final class SubscriptionError extends SubscriptionState {
  const SubscriptionError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Creating the order. The Pay button is disabled so a double tap can't open
/// two orders.
final class PaymentInProgress extends SubscriptionState {
  const PaymentInProgress();
}

/// The order exists; the page opens Razorpay checkout with [response].
final class PaymentInitiated extends SubscriptionState {
  const PaymentInitiated(this.response);

  final SubscribeResponse response;

  @override
  List<Object?> get props => [response];
}

/// Checkout succeeded; confirming with the API. The page blocks the screen.
final class PaymentVerifying extends SubscriptionState {
  const PaymentVerifying();
}

final class PaymentSuccess extends SubscriptionState {
  const PaymentSuccess(this.subscription);

  final Subscription subscription;

  @override
  List<Object?> get props => [subscription];
}

enum PaymentFailureKind {
  /// The order could not be created; see [PaymentFailure.failure].
  request,

  /// Razorpay reported an error; see [PaymentFailure.message].
  gateway,

  /// Paid, but the API could not confirm yet; the webhook will activate.
  activationPending,
  webUnsupported,
  externalWallet,
}

final class PaymentFailure extends SubscriptionState {
  const PaymentFailure(this.kind, {this.failure, this.message});

  final PaymentFailureKind kind;
  final Failure? failure;
  final String? message;

  @override
  List<Object?> get props => [kind, failure, message];
}

/// The current subscription, and checkout from order to activation.
///
/// After activation it refreshes the shared profile (Pro gates rebuild) and
/// renews the access token (the API reads the tier from its claims).
@injectable
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repository, this._profile, this._tokens)
    : super(const SubscriptionInitial());

  final BillingRepository _repository;
  final ProfileCubit _profile;
  final TokenRenewal _tokens;

  @visibleForTesting
  bool debugMode = kDebugMode;

  @visibleForTesting
  bool isWeb = kIsWeb;

  /// Delay before the n-th activation retry (n = 1, 2, …).
  @visibleForTesting
  Duration Function(int attempt) retryDelay = (attempt) =>
      Duration(seconds: 1 << (attempt - 1));

  static const _maxActivationAttempts = 3;

  Future<void> load() async {
    emit(const SubscriptionLoading());
    Result<Subscription?>? last;
    await for (final result in _repository.watchCurrentSubscription()) {
      last = result;
      if (result case Ok(:final value)) emit(SubscriptionLoaded(value));
    }
    if (last case Err(:final failure) when state is! SubscriptionLoaded) {
      emit(SubscriptionError(failure));
    }
  }

  Future<void> initiatePayment(String planCode, {String? couponCode}) async {
    if (state is PaymentInProgress || state is PaymentVerifying) return;
    emit(const PaymentInProgress());

    final result = await _repository.subscribe(
      planCode,
      couponCode: couponCode,
    );
    switch (result) {
      case Err(:final failure):
        emit(PaymentFailure(PaymentFailureKind.request, failure: failure));
      case Ok(value: final response) when response.isStub && debugMode:
        // No gateway on a development server: activate straight away. The
        // payment id must be unique per order (it is a unique key server-side).
        await _activate(
          CheckoutSuccess(
            orderId: response.gatewayOrderId,
            paymentId: 'stub_pay_${response.gatewayOrderId}',
            signature: 'stub',
          ),
        );
      case Ok() when isWeb:
        emit(const PaymentFailure(PaymentFailureKind.webUnsupported));
      case Ok(value: final response):
        emit(PaymentInitiated(response));
    }
  }

  Future<void> onPaymentSuccess(CheckoutSuccess payment) => _activate(payment);

  void onPaymentError({required bool cancelled, String? message}) {
    // Closing the sheet is a choice, not an error.
    emit(
      cancelled
          ? const SubscriptionInitial()
          : PaymentFailure(PaymentFailureKind.gateway, message: message),
    );
  }

  void onExternalWallet(String? wallet) =>
      emit(const PaymentFailure(PaymentFailureKind.externalWallet));

  Future<Result<void>> cancelSubscription() async {
    final result = await _repository.cancelSubscription();
    if (result is Ok) {
      await _afterTierChange();
      await load();
    }
    return result;
  }

  Future<void> _activate(CheckoutSuccess payment) async {
    emit(const PaymentVerifying());
    for (var attempt = 1; ; attempt++) {
      final result = await _repository.activateSubscription(
        orderId: payment.orderId,
        paymentId: payment.paymentId,
        signature: payment.signature,
      );
      if (isClosed) return;
      switch (result) {
        case Ok(value: final subscription):
          await _afterTierChange();
          if (!isClosed) emit(PaymentSuccess(subscription));
          return;
        case Err(:final failure) when _isRetryable(failure):
          if (attempt >= _maxActivationAttempts) {
            // The money is taken; the webhook activates server-side.
            emit(const PaymentFailure(PaymentFailureKind.activationPending));
            return;
          }
          await Future<void>.delayed(retryDelay(attempt));
          if (isClosed) return;
        case Err(:final failure):
          emit(PaymentFailure(PaymentFailureKind.request, failure: failure));
          return;
      }
    }
  }

  /// A rejected request (bad signature, unknown order) will not change on
  /// retry; a lost connection or a server hiccup may.
  static bool _isRetryable(Failure failure) => switch (failure) {
    NetworkFailure() => true,
    ServerFailure(:final statusCode) =>
      statusCode == null || statusCode >= 500 || statusCode == 409,
    _ => false,
  };

  Future<void> _afterTierChange() async {
    await _tokens.renewNow();
    await _profile.refresh();
  }
}
