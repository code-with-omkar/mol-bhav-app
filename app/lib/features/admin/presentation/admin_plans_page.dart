import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_billing.dart';
import 'admin_plans_cubit.dart';

/// "₹149 / month" in the app's language.
String planPriceLabel(AppLocalizations l10n, AdminPlan plan) {
  final price = formatInr(plan.price);
  return plan.period == PlanPeriod.monthly
      ? l10n.adminPlanPerMonth(price)
      : l10n.adminPlanPerYear(price);
}

String _periodLabel(AppLocalizations l10n, PlanPeriod p) => switch (p) {
  PlanPeriod.monthly => l10n.adminPlanMonthly,
  PlanPeriod.yearly => l10n.adminPlanYearly,
};

/// The subscription plans. Tap one to change its name, price or on/off; the
/// button below adds a plan.
class AdminPlansPage extends StatelessWidget {
  const AdminPlansPage({super.key});

  Future<void> _open(BuildContext context, {AdminPlan? plan}) {
    final cubit = context.read<AdminPlansCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => _PlanSheet(
        plan: plan,
        onSave: (draft) =>
            plan == null ? cubit.create(draft) : cubit.update(plan.id, draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<AdminPlansCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminPlansTitle),
      body: BlocBuilder<AdminPlansCubit, DataState<List<AdminPlan>>>(
        builder: (context, state) {
          final plans = state.data;
          if (plans == null) {
            return state.status == LoadStatus.failure
                ? MbErrorView(failure: state.failure!, onRetry: cubit.load)
                : const MbLoadingView();
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                Text(
                  l10n.adminPlansIntro,
                  style: context.mbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s3),
                if (plans.isEmpty)
                  MbEmptyView(message: l10n.adminPlansEmpty)
                else
                  for (final plan in plans) ...[
                    _PlanCard(
                      plan: plan,
                      onTap: () => _open(context, plan: plan),
                    ),
                    const SizedBox(height: MbSpacing.s2),
                  ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminPlansNew,
            block: true,
            onPressed: () => _open(context),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});

  final AdminPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
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
                  child: Text(plan.name, style: t.title.copyWith(color: c.ink)),
                ),
                const SizedBox(width: MbSpacing.s2),
                MbBadge(
                  label: plan.isActive
                      ? l10n.campaignStatusActive
                      : l10n.adminPlanOff,
                  tone: plan.isActive ? MbBadgeTone.best : MbBadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: MbSpacing.s1),
            Text(
              planPriceLabel(l10n, plan),
              style: t.body.copyWith(color: c.ink),
            ),
            Text(plan.code, style: t.caption.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// Add or edit a plan. Stays open if the save is refused, showing why.
class _PlanSheet extends StatefulWidget {
  const _PlanSheet({required this.plan, required this.onSave});

  final AdminPlan? plan;
  final Future<Failure?> Function(PlanDraft draft) onSave;

  @override
  State<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<_PlanSheet> {
  late PlanDraft _draft = widget.plan == null
      ? const PlanDraft()
      : PlanDraft.from(widget.plan!);
  late final _code = TextEditingController(text: _draft.code);
  late final _name = TextEditingController(text: _draft.name);
  late final _price = TextEditingController(text: _draft.price);

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  bool get _isNew => widget.plan == null;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (planProblems(_draft, isNew: _isNew).isNotEmpty) {
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
    final problems = _showErrors
        ? planProblems(_draft, isNew: _isNew)
        : <PlanProblem>{};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? l10n.adminPlansNew : l10n.adminPlanEditTitle,
              style: t.title.copyWith(color: c.ink),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _code,
              label: l10n.adminPlanCode,
              helper: _isNew ? l10n.adminPlanCodeHint : null,
              enabled: _isNew && !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(BillingLimits.planCode),
              ],
              error: problems.contains(PlanProblem.codeInvalid)
                  ? l10n.adminPlanErrCode
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(code: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _name,
              label: l10n.adminPlanName,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(BillingLimits.planName),
              ],
              error: problems.contains(PlanProblem.nameInvalid)
                  ? l10n.adminPlanErrName
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(name: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _price,
              label: l10n.adminPlanPrice,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: problems.contains(PlanProblem.priceInvalid)
                  ? l10n.adminPlanErrPrice
                  : null,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(price: v)),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbSelectField<PlanPeriod>(
              label: l10n.adminPlanPeriod,
              items: [
                for (final p in PlanPeriod.values)
                  MbSelectItem(value: p, label: _periodLabel(l10n, p)),
              ],
              value: _draft.period,
              // The billing cycle is fixed once the plan exists.
              onChanged: _isNew && !_saving
                  ? (p) => setState(() => _draft = _draft.copyWith(period: p))
                  : null,
            ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.adminPlanActive,
                  style: t.body.copyWith(color: c.ink),
                ),
                value: _draft.isActive,
                onChanged: _saving
                    ? null
                    : (v) =>
                          setState(() => _draft = _draft.copyWith(isActive: v)),
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
              label: l10n.adminPlanSave,
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
