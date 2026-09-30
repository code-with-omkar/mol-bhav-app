import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/payments/razorpay_service.dart';
import 'package:mol_bhav/core/session/token_renewal.dart';
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart';
import 'package:mol_bhav/features/billing/domain/billing.dart';
import 'package:mol_bhav/features/billing/presentation/cubit/subscription_cubit.dart';

class _MockRepo extends Mock implements BillingRepository {}

class _MockProfile extends Mock implements ProfileCubit {}

class _MockTokens extends Mock implements TokenRenewal {}

SubscribeResponse _order({required bool stub}) => SubscribeResponse(
  subscriptionId: 's1',
  gatewayOrderId: 'order_1',
  amountPaise: 49900,
  currency: 'INR',
  keyId: stub ? '' : 'rzp_test',
  planName: 'Pro',
  cycle: BillingCycle.monthly,
  isStub: stub,
);

final _active = Subscription(
  id: 's1',
  planCode: 'pro-monthly',
  planName: 'Pro',
  status: SubscriptionStatus.active,
  cycle: BillingCycle.monthly,
  expiresAt: DateTime(2026, 10, 28),
);

const _paid = CheckoutSuccess(
  orderId: 'order_1',
  paymentId: 'pay_1',
  signature: 'sig',
);

void main() {
  late _MockRepo repo;
  late _MockProfile profile;
  late _MockTokens tokens;

  setUp(() {
    repo = _MockRepo();
    profile = _MockProfile();
    tokens = _MockTokens();
    when(() => profile.refresh()).thenAnswer((_) async {});
    when(() => tokens.renewNow()).thenAnswer((_) async {});
  });

  SubscriptionCubit build({bool debug = false, bool web = false}) =>
      SubscriptionCubit(repo, profile, tokens)
        ..debugMode = debug
        ..isWeb = web
        ..retryDelay = (_) => Duration.zero;

  void activateAnswers(List<Result<Subscription>> answers) {
    var call = 0;
    when(
      () => repo.activateSubscription(
        orderId: any(named: 'orderId'),
        paymentId: any(named: 'paymentId'),
        signature: any(named: 'signature'),
      ),
    ).thenAnswer((_) async => answers[call++]);
  }

  blocTest<SubscriptionCubit, SubscriptionState>(
    'a stub gateway in a debug build activates without Razorpay',
    setUp: () {
      when(() => repo.subscribe(any(), couponCode: any(named: 'couponCode')))
          .thenAnswer((_) async => Ok(_order(stub: true)));
      activateAnswers([Ok(_active)]);
    },
    build: () => build(debug: true),
    act: (c) => c.initiatePayment('pro-monthly'),
    expect: () => [
      const PaymentInProgress(),
      const PaymentVerifying(),
      PaymentSuccess(_active),
    ],
    verify: (_) => verify(
      () => repo.activateSubscription(
        orderId: 'order_1',
        paymentId: 'stub_pay_order_1',
        signature: 'stub',
      ),
    ).called(1),
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'a real order opens checkout',
    setUp: () =>
        when(() => repo.subscribe(any(), couponCode: any(named: 'couponCode')))
            .thenAnswer((_) async => Ok(_order(stub: false))),
    build: build,
    act: (c) => c.initiatePayment('pro-monthly', couponCode: 'LAUNCH50'),
    expect: () => [
      const PaymentInProgress(),
      PaymentInitiated(_order(stub: false)),
    ],
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'the web cannot pay',
    setUp: () =>
        when(() => repo.subscribe(any(), couponCode: any(named: 'couponCode')))
            .thenAnswer((_) async => Ok(_order(stub: false))),
    build: () => build(web: true),
    act: (c) => c.initiatePayment('pro-monthly'),
    expect: () => const [
      PaymentInProgress(),
      PaymentFailure(PaymentFailureKind.webUnsupported),
    ],
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'closing the checkout sheet returns quietly to the start',
    build: build,
    seed: () => PaymentInitiated(_order(stub: false)),
    act: (c) => c.onPaymentError(cancelled: true, message: 'cancelled'),
    expect: () => const [SubscriptionInitial()],
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'success refreshes the profile and renews the token',
    setUp: () => activateAnswers([Ok(_active)]),
    build: build,
    act: (c) => c.onPaymentSuccess(_paid),
    expect: () => [const PaymentVerifying(), PaymentSuccess(_active)],
    verify: (_) {
      verify(() => tokens.renewNow()).called(1);
      verify(() => profile.refresh()).called(1);
    },
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'activation that keeps failing on the network ends as pending',
    setUp: () => activateAnswers(const [
      Err(NetworkFailure()),
      Err(NetworkFailure()),
      Err(NetworkFailure()),
    ]),
    build: build,
    act: (c) => c.onPaymentSuccess(_paid),
    expect: () => const [
      PaymentVerifying(),
      PaymentFailure(PaymentFailureKind.activationPending),
    ],
    verify: (_) {
      verify(
        () => repo.activateSubscription(
          orderId: any(named: 'orderId'),
          paymentId: any(named: 'paymentId'),
          signature: any(named: 'signature'),
        ),
      ).called(3);
      verifyNever(() => profile.refresh());
    },
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'a transient failure is retried until activation succeeds',
    setUp: () => activateAnswers([const Err(NetworkFailure()), Ok(_active)]),
    build: build,
    act: (c) => c.onPaymentSuccess(_paid),
    expect: () => [const PaymentVerifying(), PaymentSuccess(_active)],
  );

  blocTest<SubscriptionCubit, SubscriptionState>(
    'a rejected signature is not retried',
    setUp: () => activateAnswers(const [Err(ServerFailure(statusCode: 400))]),
    build: build,
    act: (c) => c.onPaymentSuccess(_paid),
    expect: () => const [
      PaymentVerifying(),
      PaymentFailure(
        PaymentFailureKind.request,
        failure: ServerFailure(statusCode: 400),
      ),
    ],
  );
}
