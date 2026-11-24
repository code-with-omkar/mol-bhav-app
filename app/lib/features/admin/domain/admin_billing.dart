import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// How often a plan bills (the API's `BillingPeriod`).
enum PlanPeriod {
  monthly('Monthly'),
  yearly('Yearly');

  const PlanPeriod(this.wire);

  final String wire;

  /// A period this build does not know reads as [monthly].
  static PlanPeriod fromWire(String value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => monthly);
}

/// Limits the API enforces on plans and coupons; the forms check the same ones.
abstract final class BillingLimits {
  static const planCode = 32;
  static const planName = 100;
  static const couponCode = 50;
}

/// Letters, digits, `-` and `_`: what a plan or coupon code may contain.
final _codePattern = RegExp(r'^[A-Za-z0-9_-]+$');

/// `149`, `149.5` or `149.50` as a number; null for anything else (a comma or
/// a third decimal place is a typing slip, not a price).
double? parseRupees(String text) {
  final t = text.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
  return double.tryParse(t);
}

/// Rupees as whole paise (`49.90` → 4990), without floating-point drift.
int rupeesToPaise(double rupees) => (rupees * 100).round();

/// A subscription plan (`GET /admin/billing/plans`). The price is in rupees.
class AdminPlan extends Equatable {
  const AdminPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.currency,
    required this.period,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final double price;
  final String currency;
  final PlanPeriod period;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    price,
    currency,
    period,
    isActive,
  ];
}

enum PlanProblem { codeInvalid, nameInvalid, priceInvalid }

/// A plan as typed into the form. [code] and [period] are fixed once created
/// (customers' billing history refers to them), so only a new plan uses them.
class PlanDraft extends Equatable {
  const PlanDraft({
    this.code = '',
    this.name = '',
    this.price = '',
    this.period = PlanPeriod.monthly,
    this.isActive = true,
  });

  factory PlanDraft.from(AdminPlan p) => PlanDraft(
    code: p.code,
    name: p.name,
    price: p.price == p.price.roundToDouble()
        ? p.price.toStringAsFixed(0)
        : p.price.toStringAsFixed(2),
    period: p.period,
    isActive: p.isActive,
  );

  final String code;
  final String name;
  final String price;
  final PlanPeriod period;
  final bool isActive;

  PlanDraft copyWith({
    String? code,
    String? name,
    String? price,
    PlanPeriod? period,
    bool? isActive,
  }) => PlanDraft(
    code: code ?? this.code,
    name: name ?? this.name,
    price: price ?? this.price,
    period: period ?? this.period,
    isActive: isActive ?? this.isActive,
  );

  double? get priceValue => parseRupees(price);

  @override
  List<Object?> get props => [code, name, price, period, isActive];
}

/// What is wrong with [draft]; [isNew] also checks the code.
Set<PlanProblem> planProblems(PlanDraft draft, {required bool isNew}) {
  final code = draft.code.trim();
  final name = draft.name.trim();
  return {
    if (isNew &&
        (code.isEmpty ||
            code.length > BillingLimits.planCode ||
            !_codePattern.hasMatch(code)))
      PlanProblem.codeInvalid,
    if (name.isEmpty || name.length > BillingLimits.planName)
      PlanProblem.nameInvalid,
    if (draft.priceValue == null) PlanProblem.priceInvalid,
  };
}

enum CouponKind {
  percent('Percent'),
  fixed('Fixed');

  const CouponKind(this.wire);

  final String wire;

  static CouponKind fromWire(String value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => percent);
}

/// A discount code (`GET /admin/coupons`). A fixed discount and the minimum
/// amount are kept in paise.
class AdminCoupon extends Equatable {
  const AdminCoupon({
    required this.id,
    required this.code,
    required this.kind,
    required this.value,
    required this.usesCount,
    required this.validFrom,
    required this.minAmountPaise,
    required this.isActive,
    this.maxUses,
    this.validTo,
    this.planCode,
  });

  final String id;
  final String code;
  final CouponKind kind;

  /// Percent (1–100) or paise, depending on [kind].
  final int value;
  final int? maxUses;
  final int usesCount;
  final DateTime validFrom;
  final DateTime? validTo;

  /// The only plan it works on; null = any plan.
  final String? planCode;
  final int minAmountPaise;
  final bool isActive;

  /// Past its end date.
  bool isExpired(DateTime now) => validTo != null && validTo!.isBefore(now);

  /// Used up.
  bool get isUsedUp => maxUses != null && usesCount >= maxUses!;

  @override
  List<Object?> get props => [
    id,
    code,
    kind,
    value,
    maxUses,
    usesCount,
    validFrom,
    validTo,
    planCode,
    minAmountPaise,
    isActive,
  ];
}

enum CouponProblem {
  codeInvalid,
  valueInvalid,
  maxUsesInvalid,
  startMissing,
  endBeforeStart,
  minAmountInvalid,
}

/// A new coupon as typed into the form. A fixed [value] and [minAmount] are
/// typed in rupees.
class CouponDraft extends Equatable {
  const CouponDraft({
    this.code = '',
    this.kind = CouponKind.percent,
    this.value = '',
    this.maxUses = '',
    this.startsOn,
    this.endsOn,
    this.planCode,
    this.minAmount = '',
  });

  final String code;
  final CouponKind kind;
  final String value;
  final String maxUses;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String? planCode;
  final String minAmount;

  CouponDraft copyWith({
    String? code,
    CouponKind? kind,
    String? value,
    String? maxUses,
    DateTime? Function()? startsOn,
    DateTime? Function()? endsOn,
    String? Function()? planCode,
    String? minAmount,
  }) => CouponDraft(
    code: code ?? this.code,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    maxUses: maxUses ?? this.maxUses,
    startsOn: startsOn != null ? startsOn() : this.startsOn,
    endsOn: endsOn != null ? endsOn() : this.endsOn,
    planCode: planCode != null ? planCode() : this.planCode,
    minAmount: minAmount ?? this.minAmount,
  );

  /// The discount as the API takes it: percent as typed, or rupees as paise.
  int? get discountValue => switch (kind) {
    CouponKind.percent => int.tryParse(value.trim()),
    CouponKind.fixed =>
      parseRupees(value) == null ? null : rupeesToPaise(parseRupees(value)!),
  };

  int? get maxUsesValue =>
      maxUses.trim().isEmpty ? null : int.tryParse(maxUses.trim());

  int? get minAmountPaise => minAmount.trim().isEmpty
      ? 0
      : (parseRupees(minAmount) == null
            ? null
            : rupeesToPaise(parseRupees(minAmount)!));

  /// The first moment of the first day, as an instant.
  DateTime? get validFrom => startsOn == null
      ? null
      : DateTime(startsOn!.year, startsOn!.month, startsOn!.day).toUtc();

  /// The last second of the last day, as an instant; null = no end.
  DateTime? get validTo => endsOn == null
      ? null
      : DateTime(endsOn!.year, endsOn!.month, endsOn!.day, 23, 59, 59).toUtc();

  @override
  List<Object?> get props => [
    code,
    kind,
    value,
    maxUses,
    startsOn,
    endsOn,
    planCode,
    minAmount,
  ];
}

/// What is wrong with a new coupon.
Set<CouponProblem> couponProblems(CouponDraft draft) {
  final code = draft.code.trim();
  final value = draft.discountValue;
  final cap = draft.maxUsesValue;
  return {
    if (code.isEmpty ||
        code.length > BillingLimits.couponCode ||
        !_codePattern.hasMatch(code))
      CouponProblem.codeInvalid,
    if (value == null ||
        value <= 0 ||
        (draft.kind == CouponKind.percent && value > 100))
      CouponProblem.valueInvalid,
    if (draft.maxUses.trim().isNotEmpty && (cap == null || cap < 1))
      CouponProblem.maxUsesInvalid,
    if (draft.startsOn == null) CouponProblem.startMissing,
    if (draft.startsOn != null &&
        draft.endsOn != null &&
        draft.endsOn!.isBefore(draft.startsOn!))
      CouponProblem.endBeforeStart,
    if (draft.minAmountPaise == null) CouponProblem.minAmountInvalid,
  };
}

/// What an existing coupon lets an admin change: switch it off or on, move
/// its end, or change its use limit (never below the uses already made).
class CouponEdit extends Equatable {
  const CouponEdit({required this.isActive, this.endsOn, this.maxUses = ''});

  factory CouponEdit.from(AdminCoupon c) => CouponEdit(
    isActive: c.isActive,
    endsOn: c.validTo == null
        ? null
        : DateTime(
            c.validTo!.toLocal().year,
            c.validTo!.toLocal().month,
            c.validTo!.toLocal().day,
          ),
    maxUses: c.maxUses == null ? '' : '${c.maxUses}',
  );

  final bool isActive;
  final DateTime? endsOn;
  final String maxUses;

  CouponEdit copyWith({
    bool? isActive,
    DateTime? Function()? endsOn,
    String? maxUses,
  }) => CouponEdit(
    isActive: isActive ?? this.isActive,
    endsOn: endsOn != null ? endsOn() : this.endsOn,
    maxUses: maxUses ?? this.maxUses,
  );

  int? get maxUsesValue =>
      maxUses.trim().isEmpty ? null : int.tryParse(maxUses.trim());

  DateTime? get validTo => endsOn == null
      ? null
      : DateTime(endsOn!.year, endsOn!.month, endsOn!.day, 23, 59, 59).toUtc();

  @override
  List<Object?> get props => [isActive, endsOn, maxUses];
}

/// What is wrong with an edit of [coupon].
Set<CouponProblem> couponEditProblems(CouponEdit edit, AdminCoupon coupon) {
  final cap = edit.maxUsesValue;
  final startDay = DateTime(
    coupon.validFrom.toLocal().year,
    coupon.validFrom.toLocal().month,
    coupon.validFrom.toLocal().day,
  );
  return {
    if (edit.maxUses.trim().isNotEmpty &&
        (cap == null || cap < 1 || cap < coupon.usesCount))
      CouponProblem.maxUsesInvalid,
    if (edit.endsOn != null && edit.endsOn!.isBefore(startDay))
      CouponProblem.endBeforeStart,
  };
}

abstract interface class AdminBillingRepository {
  Future<Result<List<AdminPlan>>> getPlans();

  Future<Result<void>> createPlan(PlanDraft draft);

  /// Name, price and on/off; the code and period never change.
  Future<Result<void>> updatePlan(String id, PlanDraft draft);

  /// Newest first.
  Future<Result<List<AdminCoupon>>> getCoupons({
    required int page,
    required int pageSize,
  });

  Future<Result<void>> createCoupon(CouponDraft draft);

  Future<Result<void>> updateCoupon(String id, CouponEdit edit);
}
