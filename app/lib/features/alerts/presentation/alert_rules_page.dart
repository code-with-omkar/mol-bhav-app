import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../domain/alerts.dart';
import 'alert_rules_cubit.dart';

class AlertRulesPage extends StatelessWidget {
  const AlertRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(title: l10n.alertRulesTitle),
      body: BlocBuilder<AlertRulesCubit, AlertRulesState>(
        builder: (context, state) {
          final cubit = context.read<AlertRulesCubit>();
          return switch (state) {
            AlertRulesLoading() => const MbLoadingView(),
            AlertRulesError(:final failure) => MbErrorView(
              failure: failure,
              onRetry: cubit.load,
            ),
            AlertRulesLoaded(:final rules) =>
              rules.isEmpty
                  ? MbEmptyView(message: l10n.alertRulesEmpty)
                  : _RulesList(rules: rules, cubit: cubit),
          };
        },
      ),
    );
  }
}

class _RulesList extends StatelessWidget {
  const _RulesList({required this.rules, required this.cubit});

  final List<AlertRule> rules;
  final AlertRulesCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: MbSpacing.screenPadding,
      itemCount: rules.length,
      separatorBuilder: (_, _) => const SizedBox(height: MbSpacing.s3),
      itemBuilder: (context, i) => _RuleTile(rule: rules[i], cubit: cubit),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.cubit});

  final AlertRule rule;
  final AlertRulesCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;

    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: MbSpacing.s4),
        decoration: BoxDecoration(
          color: c.priceDown.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(MbRadius.md),
        ),
        child: Icon(Icons.delete_outline, color: c.priceDown),
      ),
      confirmDismiss: (_) async {
        // Optimistically remove; undo within 3 s re-adds via reload.
        return true;
      },
      onDismissed: (_) {
        final messenger = ScaffoldMessenger.of(context);
        cubit.deleteRule(rule.id);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.alertRuleDeleted),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: l10n.undo,
                onPressed: () {
                  // Re-add by restoring via update with same values.
                  cubit.updateRule(
                    rule.id,
                    UpdateAlertRuleRequest(
                      thresholdType: rule.thresholdType,
                      thresholdPercent: rule.thresholdPercent,
                      thresholdPrice: rule.thresholdPrice,
                      isActive: rule.isActive,
                    ),
                  );
                },
              ),
            ),
          );
      },
      child: GestureDetector(
        onTap: () => _showEditSheet(context, rule, cubit),
        child: Container(
          padding: const EdgeInsets.all(MbSpacing.s4),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(MbRadius.md),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rule.productName,
                      style: context.mbText.title.copyWith(color: c.ink),
                    ),
                  ),
                  _ActiveChip(isActive: rule.isActive),
                ],
              ),
              if (rule.locationName != null) ...[
                const SizedBox(height: MbSpacing.s1),
                Text(
                  rule.locationName!,
                  style: context.mbText.caption.copyWith(color: c.inkMuted),
                ),
              ],
              const SizedBox(height: MbSpacing.s2),
              Text(
                _conditionSummary(context, rule),
                style: context.mbText.body.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final color = isActive ? c.primaryText : c.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MbSpacing.s2,
        vertical: MbSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? c.primary.withValues(alpha: 0.1)
            : c.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(MbRadius.pill),
      ),
      child: Text(
        isActive
            ? context.l10n.alertRuleActiveLabel
            : context.l10n.alertRuleInactiveLabel,
        style: context.mbText.label.copyWith(color: color),
      ),
    );
  }
}

String _conditionSummary(BuildContext context, AlertRule rule) {
  final l10n = context.l10n;
  return switch (rule.thresholdType) {
    AlertThresholdType.priceBelow => l10n.alertRuleConditionBelow(
      formatInr(rule.thresholdPrice ?? 0),
    ),
    AlertThresholdType.priceAbove => l10n.alertRuleConditionAbove(
      formatInr(rule.thresholdPrice ?? 0),
    ),
    AlertThresholdType.priceDrop => l10n.alertRuleConditionDrop(
      formatPercent(rule.thresholdPercent ?? 0),
    ),
    AlertThresholdType.priceSpike => l10n.alertRuleConditionSpike(
      formatPercent(rule.thresholdPercent ?? 0),
    ),
  };
}

void _showEditSheet(
  BuildContext context,
  AlertRule rule,
  AlertRulesCubit cubit,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) => _EditSheet(rule: rule, cubit: cubit),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.rule, required this.cubit});

  final AlertRule rule;
  final AlertRulesCubit cubit;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _valueController;
  late bool _isActive;
  late bool _saving;

  bool get _isPercent =>
      widget.rule.thresholdType == AlertThresholdType.priceDrop ||
      widget.rule.thresholdType == AlertThresholdType.priceSpike;

  @override
  void initState() {
    super.initState();
    _isActive = widget.rule.isActive;
    _saving = false;
    final initial = _isPercent
        ? (widget.rule.thresholdPercent ?? 0).toString()
        : (widget.rule.thresholdPrice ?? 0).toString();
    _valueController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = num.tryParse(_valueController.text.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return;
    setState(() => _saving = true);
    await widget.cubit.updateRule(
      widget.rule.id,
      UpdateAlertRuleRequest(
        thresholdType: widget.rule.thresholdType,
        thresholdPercent: _isPercent ? parsed : null,
        thresholdPrice: _isPercent ? null : parsed,
        isActive: _isActive,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MbSpacing.s4,
        MbSpacing.s4,
        MbSpacing.s4,
        MbSpacing.s4 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.alertRulesEditTitle, style: t.h2.copyWith(color: c.ink)),
          const SizedBox(height: MbSpacing.s2),
          Text(
            widget.rule.productName,
            style: t.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s4),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isPercent
                  ? l10n.alertRulesThresholdPercentLabel
                  : l10n.alertRulesThresholdPriceLabel(
                      widget.rule.unit.isNotEmpty ? widget.rule.unit : '—',
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: MbSpacing.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.alertRulesActiveLabel,
                  style: t.body.copyWith(color: c.ink),
                ),
              ),
              Switch(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
          const SizedBox(height: MbSpacing.s4),
          Row(
            children: [
              Expanded(
                child: MbButton(
                  label: l10n.alertRulesCancel,
                  variant: MbButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                  block: true,
                ),
              ),
              const SizedBox(width: MbSpacing.s3),
              Expanded(
                child: MbButton(
                  label: l10n.alertRulesSave,
                  onPressed: _saving ? null : _save,
                  isLoading: _saving,
                  block: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
