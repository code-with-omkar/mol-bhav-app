import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/payments/razorpay_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../../../shared/widgets/mb_text_field.dart';
import '../../domain/billing.dart';
import '../cubit/coupon_cubit.dart';
import '../cubit/plans_cubit.dart';
import '../cubit/subscription_cubit.dart';

/// Price summary, coupon, and Pay. Expects [PlansCubit], [CouponCubit] and
/// [SubscriptionCubit] from the route.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.planCode});

  final String planCode;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _razorpay = getIt<RazorpayService>();

  @override
  void dispose() {
    // Drops the SDK listeners, so a late result can't reach a closed cubit.
    _razorpay.dispose();
    super.dispose();
  }

  void _openCheckout(SubscribeResponse response) {
    final cubit = context.read<SubscriptionCubit>();
    _razorpay.openCheckout(
      keyId: response.keyId,
      orderId: response.gatewayOrderId,
      amountPaise: response.amountPaise,
      currency: response.currency,
      description: response.planName,
      themeColor: context.mbColors.primary.toARGB32(),
      onSuccess: cubit.onPaymentSuccess,
      onError: cubit.onPaymentError,
      onExternalWallet: cubit.onExternalWallet,
    );
  }

  String _failureText(PaymentFailure state) {
    final l10n = context.l10n;
    return switch (state.kind) {
      PaymentFailureKind.request => failureMessage(
        context,
        state.failure ?? const UnexpectedFailure(),
      ),
      PaymentFailureKind.gateway => state.message ?? l10n.paymentFailed,
      PaymentFailureKind.activationPending => l10n.paymentActivationPending,
      PaymentFailureKind.webUnsupported => l10n.paymentsMobileOnly,
      PaymentFailureKind.externalWallet => l10n.externalWalletUnsupported,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listener: (context, state) {
        switch (state) {
          case PaymentInitiated(:final response):
            _openCheckout(response);
          case PaymentSuccess():
            context.go(AppRoutes.billingSuccess);
          case PaymentFailure():
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(_failureText(state))));
          default:
        }
      },
      builder: (context, payment) {
        final verifying = payment is PaymentVerifying;
        return PopScope(
          canPop: !verifying,
          child: Stack(
            children: [
              Scaffold(
                appBar: MbAppBar(title: l10n.checkoutTitle),
                body: BlocBuilder<PlansCubit, PlansState>(
                  builder: (context, plans) => switch (plans) {
                    PlansLoaded(:final plans) => _planOrMissing(plans, payment),
                    PlansError(:final failure) => MbErrorView(
                      failure: failure,
                      onRetry: context.read<PlansCubit>().load,
                    ),
                    _ => const MbLoadingView(),
                  },
                ),
              ),
              if (verifying) const _Verifying(),
            ],
          ),
        );
      },
    );
  }

  Widget _planOrMissing(List<Plan> plans, SubscriptionState payment) {
    for (final plan in plans) {
      if (plan.code == widget.planCode) {
        return _Checkout(plan: plan, payment: payment);
      }
    }
    return MbErrorView(
      failure: const ServerFailure(statusCode: 404),
      onRetry: () => context.go(AppRoutes.billingPlans),
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout({required this.plan, required this.payment});

  final Plan plan;
  final SubscriptionState payment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coupon = context.watch<CouponCubit>().state;
    final validation = coupon is CouponValid ? coupon.validation : null;
    final total = validation?.finalAmountPaise ?? plan.pricePaise;
    final busy = payment is PaymentInProgress || payment is PaymentVerifying;
    // A typed code must be confirmed first, or the charge would silently skip it.
    final couponPending = coupon is CouponValidating || coupon is CouponInvalid;

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        MbCard(
          child: Column(
            children: [
              _Line(
                label: l10n.summaryPlan,
                value:
                    '${plan.name} · ${plan.cycle == BillingCycle.yearly ? l10n.yearlyBillingPlain : l10n.monthlyBilling}',
              ),
              _Line(
                label: l10n.priceLabel,
                value: formatPaise(
                  validation?.originalAmountPaise ?? plan.pricePaise,
                ),
              ),
              if (validation != null && validation.discountPaise > 0)
                _Line(
                  label: l10n.summaryDiscount,
                  value: '− ${formatPaise(validation.discountPaise)}',
                ),
              const Divider(height: MbSpacing.s5),
              _Line(
                label: l10n.summaryTotal,
                value: formatPaise(total),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: MbSpacing.s4),
        MbTextField(
          label: l10n.couponCode,
          enabled: !busy,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(50),
            TextInputFormatter.withFunction(
              (_, next) => next.copyWith(text: next.text.toUpperCase()),
            ),
          ],
          onChanged: (code) =>
              context.read<CouponCubit>().onCodeChanged(code, plan.code),
          helper: validation == null
              ? null
              : l10n.couponApplied(formatPaise(validation.discountPaise)),
          error: switch (coupon) {
            CouponInvalid(failure: final Failure f) => failureMessage(
              context,
              f,
            ),
            CouponInvalid() => l10n.couponInvalid,
            _ => null,
          },
        ),
        if (coupon is CouponValidating)
          const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: MbSpacing.s6),
        MbButton(
          label: l10n.proceedToPay(formatPaise(total)),
          block: true,
          size: MbButtonSize.lg,
          isLoading: busy,
          onPressed: busy || couponPending
              ? null
              : () => context.read<SubscriptionCubit>().initiatePayment(
                  plan.code,
                  couponCode: coupon is CouponValid ? coupon.code : null,
                ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final style = (strong ? context.mbText.title : context.mbText.body)
        .copyWith(color: c.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MbSpacing.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style.copyWith(color: strong ? c.ink : c.inkMuted),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Blocks the screen while the API confirms the payment.
class _Verifying extends StatelessWidget {
  const _Verifying();

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: MbCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: MbSpacing.s3),
                Material(
                  type: MaterialType.transparency,
                  child: Text(
                    context.l10n.confirmingPayment,
                    style: context.mbText.body.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
