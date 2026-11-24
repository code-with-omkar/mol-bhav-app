import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_field_frame.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_billing.dart';
import 'admin_coupons_cubit.dart';

/// "20% off" or "₹50 off" in the app's language.
String couponDiscountLabel(AppLocalizations l10n, AdminCoupon c) =>
    c.kind == CouponKind.percent
    ? l10n.adminCouponPercentOff(c.value)
    : l10n.adminCouponAmountOff(formatPaise(c.value));

/// Discount codes: newest first, with "load more" paging. Tap one to switch
/// it on or off, move its end or change its use limit; the button adds one.
class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminCouponsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open({AdminCoupon? coupon}) {
    final cubit = context.read<AdminCouponsCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => coupon == null
          ? _NewCouponSheet(plans: cubit.state.plans, onSave: cubit.create)
          : _EditCouponSheet(
              coupon: coupon,
              onSave: (edit) => cubit.update(coupon.id, edit),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminCouponsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminCouponsTitle),
      body: BlocBuilder<AdminCouponsCubit, AdminCouponsState>(
        builder: (context, state) {
          if (state.coupons.isEmpty) {
            return switch (state.status) {
              LoadStatus.failure => MbErrorView(
                failure: state.failure!,
                onRetry: cubit.load,
              ),
              LoadStatus.ready => MbEmptyView(message: l10n.adminCouponsEmpty),
              _ => const MbLoadingView(),
            };
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: MbSpacing.screenPadding,
              itemCount: state.coupons.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: MbSpacing.s2),
              itemBuilder: (context, i) => i >= state.coupons.length
                  ? const Padding(
                      padding: EdgeInsets.all(MbSpacing.s3),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _CouponCard(
                      coupon: state.coupons[i],
                      onTap: () => _open(coupon: state.coupons[i]),
                    ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminCouponsNew,
            block: true,
            onPressed: _open,
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.onTap});

  final AdminCoupon coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final expired = coupon.isExpired(DateTime.now());
    final (label, tone) = !coupon.isActive
        ? (l10n.adminCouponOff, MbBadgeTone.neutral)
        : expired
        ? (l10n.adminCouponExpired, MbBadgeTone.neutral)
        : coupon.isUsedUp
        ? (l10n.adminCouponUsedUp, MbBadgeTone.neutral)
        : (l10n.campaignStatusActive, MbBadgeTone.best);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.code,
                    style: t.title.copyWith(color: c.ink),
                  ),
                ),
                const SizedBox(width: MbSpacing.s2),
                MbBadge(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: MbSpacing.s1),
            Text(
              [
                couponDiscountLabel(l10n, coupon),
                coupon.planCode ?? l10n.adminCouponAnyPlan,
                if (coupon.minAmountPaise > 0)
                  l10n.adminCouponMinNote(formatPaise(coupon.minAmountPaise)),
              ].join(' · '),
              style: t.body.copyWith(color: c.ink),
            ),
            Text(
              [
                coupon.validTo == null
                    ? l10n.adminCouponFrom(
                        day.format(coupon.validFrom.toLocal()),
                      )
                    : '${day.format(coupon.validFrom.toLocal())} – '
                          '${day.format(coupon.validTo!.toLocal())}',
                coupon.maxUses == null
                    ? l10n.adminCouponUsed(coupon.usesCount)
                    : l10n.adminCouponUsedOf(coupon.usesCount, coupon.maxUses!),
              ].join(' · '),
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> _pickDay(BuildContext context, DateTime? current) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: current ?? now,
    firstDate: DateTime(now.year - 2),
    lastDate: DateTime(now.year + 5),
  );
}

/// Add a coupon. Stays open if the save is refused, showing why.
class _NewCouponSheet extends StatefulWidget {
  const _NewCouponSheet({required this.plans, required this.onSave});

  final List<AdminPlan> plans;
  final Future<Failure?> Function(CouponDraft draft) onSave;

  @override
  State<_NewCouponSheet> createState() => _NewCouponSheetState();
}

class _NewCouponSheetState extends State<_NewCouponSheet> {
  CouponDraft _draft = CouponDraft(startsOn: _today());
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _maxUses = TextEditingController();
  final _min = TextEditingController();

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    for (final c in [_code, _value, _maxUses, _min]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (couponProblems(_draft).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(_draft);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final problems = _showErrors ? couponProblems(_draft) : <CouponProblem>{};
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final percent = _draft.kind == CouponKind.percent;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminCouponsNew, style: t.title.copyWith(color: c.ink)),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _code,
              label: l10n.adminCouponCode,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(BillingLimits.couponCode),
              ],
              error: problems.contains(CouponProblem.codeInvalid)
                  ? l10n.adminCouponErrCode
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(code: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            Wrap(
              spacing: MbSpacing.s2,
              children: [
                for (final k in CouponKind.values)
                  ChoiceChip(
                    label: Text(
                      k == CouponKind.percent
                          ? l10n.adminCouponPercent
                          : l10n.adminCouponFixed,
                    ),
                    selected: _draft.kind == k,
                    onSelected: _saving
                        ? null
                        : (_) =>
                              setState(() => _draft = _draft.copyWith(kind: k)),
                  ),
              ],
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _value,
              label: percent
                  ? l10n.adminCouponValuePercent
                  : l10n.adminCouponValueFixed,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: problems.contains(CouponProblem.valueInvalid)
                  ? (percent
                        ? l10n.adminCouponErrPercent
                        : l10n.adminCouponErrAmount)
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(value: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbSelectField<String>(
              label: l10n.adminCouponPlan,
              items: [
                MbSelectItem(value: '', label: l10n.adminCouponAnyPlan),
                for (final p in widget.plans)
                  MbSelectItem(value: p.code, label: p.name),
              ],
              value: _draft.planCode ?? '',
              onChanged: _saving
                  ? null
                  : (code) => setState(
                      () => _draft = _draft.copyWith(
                        planCode: () => code.isEmpty ? null : code,
                      ),
                    ),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _min,
              label: l10n.adminCouponMin,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: problems.contains(CouponProblem.minAmountInvalid)
                  ? l10n.adminCouponErrMin
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(minAmount: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _maxUses,
              label: l10n.adminCouponMaxUses,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              error: problems.contains(CouponProblem.maxUsesInvalid)
                  ? l10n.adminCouponErrMaxUses
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(maxUses: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbFieldFrame(
              label: l10n.adminCouponStarts,
              error: problems.contains(CouponProblem.startMissing)
                  ? l10n.adminCampaignErrRequired
                  : null,
              onTap: _saving
                  ? null
                  : () async {
                      final picked = await _pickDay(context, _draft.startsOn);
                      if (picked != null && mounted) {
                        setState(
                          () =>
                              _draft = _draft.copyWith(startsOn: () => picked),
                        );
                      }
                    },
              child: Text(
                _draft.startsOn == null
                    ? l10n.adminCampaignPickDate
                    : day.format(_draft.startsOn!),
                style: t.fieldInput.copyWith(color: c.ink),
              ),
            ),
            const SizedBox(height: MbSpacing.s3),
            _EndDateField(
              endsOn: _draft.endsOn,
              error: problems.contains(CouponProblem.endBeforeStart)
                  ? l10n.adminCouponErrDates
                  : null,
              enabled: !_saving,
              onChanged: (d) =>
                  setState(() => _draft = _draft.copyWith(endsOn: () => d)),
            ),
            if (_failure != null) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                failureMessage(context, _failure!),
                style: t.caption.copyWith(color: c.priceUp),
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.adminCouponSave,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// An optional end date: pick one, or remove it.
class _EndDateField extends StatelessWidget {
  const _EndDateField({
    required this.endsOn,
    required this.onChanged,
    required this.enabled,
    this.error,
  });

  final DateTime? endsOn;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MbFieldFrame(
          label: l10n.adminCouponEnds,
          error: error,
          onTap: enabled
              ? () async {
                  final picked = await _pickDay(context, endsOn);
                  if (picked != null) onChanged(picked);
                }
              : null,
          child: Text(
            endsOn == null ? l10n.adminCouponNoEnd : day.format(endsOn!),
            style: t.fieldInput.copyWith(
              color: endsOn == null ? c.inkMuted : c.ink,
            ),
          ),
        ),
        if (endsOn != null)
          TextButton(
            onPressed: enabled ? () => onChanged(null) : null,
            child: Text(l10n.adminCouponClearEnd),
          ),
      ],
    );
  }
}

/// Edit what an existing coupon allows: on/off, end date, use limit.
class _EditCouponSheet extends StatefulWidget {
  const _EditCouponSheet({required this.coupon, required this.onSave});

  final AdminCoupon coupon;
  final Future<Failure?> Function(CouponEdit edit) onSave;

  @override
  State<_EditCouponSheet> createState() => _EditCouponSheetState();
}

class _EditCouponSheetState extends State<_EditCouponSheet> {
  late CouponEdit _edit = CouponEdit.from(widget.coupon);
  late final _maxUses = TextEditingController(text: _edit.maxUses);

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  @override
  void dispose() {
    _maxUses.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (couponEditProblems(_edit, widget.coupon).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(_edit);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final coupon = widget.coupon;
    final problems = _showErrors
        ? couponEditProblems(_edit, coupon)
        : <CouponProblem>{};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(coupon.code, style: t.title.copyWith(color: c.ink)),
            Text(
              '${couponDiscountLabel(l10n, coupon)} · '
              '${coupon.planCode ?? l10n.adminCouponAnyPlan} · '
              '${l10n.adminCouponUsed(coupon.usesCount)}',
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.adminCouponActive,
                style: t.body.copyWith(color: c.ink),
              ),
              value: _edit.isActive,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _edit = _edit.copyWith(isActive: v)),
            ),
            _EndDateField(
              endsOn: _edit.endsOn,
              error: problems.contains(CouponProblem.endBeforeStart)
                  ? l10n.adminCouponErrDates
                  : null,
              enabled: !_saving,
              onChanged: (d) =>
                  setState(() => _edit = _edit.copyWith(endsOn: () => d)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _maxUses,
              label: l10n.adminCouponMaxUses,
              helper: l10n.adminCouponMaxUsesNote(coupon.usesCount),
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              error: problems.contains(CouponProblem.maxUsesInvalid)
                  ? l10n.adminCouponErrMaxUsesBelow(coupon.usesCount)
                  : null,
              onChanged: (v) =>
                  setState(() => _edit = _edit.copyWith(maxUses: v)),
            ),
            if (_failure != null) ...[
              const SizedBox(height: MbSpacing.s2),
              Text(
                failureMessage(context, _failure!),
                style: t.caption.copyWith(color: c.priceUp),
              ),
            ],
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.adminCouponSave,
              block: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
