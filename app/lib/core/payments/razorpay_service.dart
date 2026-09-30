import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// What checkout returned on success: the three values activation verifies.
class CheckoutSuccess {
  const CheckoutSuccess({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

/// Razorpay's mobile checkout sheet. Android/iOS only — callers must not open
/// it on the web.
///
/// The SDK is created on first use, not at startup. Callbacks are bound per
/// checkout and dropped after the first terminal event, so a screen that has
/// gone away is never called back.
@lazySingleton
class RazorpayService {
  Razorpay? _razorpay;
  void Function(CheckoutSuccess)? _onSuccess;
  void Function({required bool cancelled, String? message})? _onError;
  void Function(String? wallet)? _onExternalWallet;

  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String currency,
    required String description,
    required int themeColor,
    required void Function(CheckoutSuccess) onSuccess,
    required void Function({required bool cancelled, String? message}) onError,
    required void Function(String? wallet) onExternalWallet,
    String? contact,
  }) {
    assert(!kIsWeb, 'razorpay_flutter has no web implementation');
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    final razorpay = _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    razorpay.open({
      'key': keyId,
      'amount': amountPaise,
      'currency': currency,
      'order_id': orderId,
      'name': 'MolBhav',
      'description': description,
      if (contact != null) 'prefill': {'contact': contact},
      'theme': {'color': _hex(themeColor)},
    });
  }

  void dispose() {
    _clearCallbacks();
    _razorpay?.clear();
    _razorpay = null;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    final callback = _onSuccess;
    _clearCallbacks();
    callback?.call(
      CheckoutSuccess(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _handleError(PaymentFailureResponse response) {
    final callback = _onError;
    _clearCallbacks();
    callback?.call(
      cancelled: response.code == Razorpay.PAYMENT_CANCELLED,
      message: response.message,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final callback = _onExternalWallet;
    _clearCallbacks();
    callback?.call(response.walletName);
  }

  void _clearCallbacks() {
    _onSuccess = null;
    _onError = null;
    _onExternalWallet = null;
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
