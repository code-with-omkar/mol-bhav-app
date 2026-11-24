import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_products.dart';
import '../domain/admin_units.dart';
import 'admin_units_cubit.dart';

String _dimensionLabel(AppLocalizations l10n, UnitDimension d) => switch (d) {
  UnitDimension.mass => l10n.adminUnitDimMass,
  UnitDimension.volume => l10n.adminUnitDimVolume,
  UnitDimension.count => l10n.adminUnitDimCount,
  UnitDimension.length => l10n.adminUnitDimLength,
  UnitDimension.area => l10n.adminUnitDimArea,
};

/// The catalog's units of measure. Tap one to rename it or switch it off; the
/// button below adds a unit.
class AdminUnitsPage extends StatelessWidget {
  const AdminUnitsPage({super.key});

  Future<void> _open(BuildContext context, {AdminUnit? unit}) {
    final cubit = context.read<AdminUnitsCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => _UnitSheet(
        unit: unit,
        onCreate: cubit.create,
        onUpdate: cubit.update,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<AdminUnitsCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminUnitsTitle),
      body: BlocBuilder<AdminUnitsCubit, DataState<List<AdminUnit>>>(
        builder: (context, state) {
          final units = state.data;
          if (units == null) {
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
                  l10n.adminUnitsIntro,
                  style: context.mbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s3),
                if (units.isEmpty)
                  MbEmptyView(message: l10n.adminUnitsEmpty)
                else
                  for (final unit in units) ...[
                    _UnitCard(
                      unit: unit,
                      onTap: () => _open(context, unit: unit),
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
            label: l10n.adminUnitNew,
            block: true,
            onPressed: () => _open(context),
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit, required this.onTap});

  final AdminUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final factor = unit.toBaseFactor == unit.toBaseFactor.roundToDouble()
        ? unit.toBaseFactor.toStringAsFixed(0)
        : unit.toBaseFactor.toString();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MbRadius.md),
      child: MbCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${unit.label} (${unit.symbol})',
                    style: t.title.copyWith(color: c.ink),
                  ),
                  Text(
                    '${unit.code} · ${_dimensionLabel(l10n, unit.dimension)}'
                    ' · 1 = $factor ${unit.dimension.baseUnit}',
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (!unit.isActive)
              MbBadge(label: l10n.adminPlanOff, tone: MbBadgeTone.neutral),
          ],
        ),
      ),
    );
  }
}

/// Add or edit a unit. A new unit sets its code, what it measures and its
/// factor (all fixed afterwards); an existing one changes its symbol, names
/// and on/off. Stays open if the save is refused, showing why.
class _UnitSheet extends StatefulWidget {
  const _UnitSheet({
    required this.unit,
    required this.onCreate,
    required this.onUpdate,
  });

  final AdminUnit? unit;
  final Future<Failure?> Function({
    required String code,
    required String symbol,
    required UnitDimension dimension,
    required double toBaseFactor,
    required Map<String, String> names,
  })
  onCreate;
  final Future<Failure?> Function(AdminUnit unit) onUpdate;

  @override
  State<_UnitSheet> createState() => _UnitSheetState();
}

class _UnitSheetState extends State<_UnitSheet> {
  late final _code = TextEditingController();
  late final _symbol = TextEditingController(text: widget.unit?.symbol ?? '');
  late final _factor = TextEditingController();
  late final Map<String, TextEditingController> _names = {
    for (final lang in productNameLanguages)
      lang: TextEditingController(text: widget.unit?.nameIn(lang) ?? ''),
  };
  UnitDimension? _dimension;
  late bool _isActive = widget.unit?.isActive ?? true;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  bool get _isNew => widget.unit == null;

  Map<String, String> get _values => {
    for (final e in _names.entries) e.key: e.value.text,
  };

  Set<UnitProblem> get _problems => {
    ...unitProblems(
      isNew: _isNew,
      code: _code.text,
      symbol: _symbol.text,
      factor: _factor.text,
      names: _values,
    ),
    if (_isNew && _dimension == null) UnitProblem.dimensionMissing,
  };

  @override
  void dispose() {
    _code.dispose();
    _symbol.dispose();
    _factor.dispose();
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_problems.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    final unit = widget.unit;
    final failure = unit == null
        ? await widget.onCreate(
            code: _code.text,
            symbol: _symbol.text,
            dimension: _dimension!,
            toBaseFactor: parseUnitFactor(_factor.text)!,
            names: _values,
          )
        : await widget.onUpdate(
            unit.edited(
              symbol: _symbol.text,
              names: _values,
              isActive: _isActive,
            ),
          );
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
    final problems = _showErrors ? _problems : <UnitProblem>{};
    final labels = {
      'en': l10n.adminProductNameEn,
      'hi': l10n.adminProductNameHi,
      'mr': l10n.adminProductNameMr,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? l10n.adminUnitNew : l10n.adminUnitEdit,
              style: t.title.copyWith(color: c.ink),
            ),
            if (_isNew) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _code,
                label: l10n.adminProductCode,
                helper: l10n.adminCategoryCodeHint,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                ],
                error: problems.contains(UnitProblem.codeInvalid)
                    ? l10n.adminProductErrCode
                    : null,
              ),
            ],
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _symbol,
              label: l10n.adminUnitSymbol,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(unitSymbolMaxLength),
              ],
              error: problems.contains(UnitProblem.symbolInvalid)
                  ? l10n.adminUnitErrSymbol
                  : null,
            ),
            for (final lang in productNameLanguages) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _names[lang],
                label: labels[lang],
                helper: lang == 'en' ? null : l10n.adminProductNameOptional,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(productNameMaxLength),
                ],
                error:
                    lang == 'en' &&
                        problems.contains(UnitProblem.englishMissing)
                    ? l10n.adminProductErrEnglish
                    : null,
              ),
            ],
            if (_isNew) ...[
              const SizedBox(height: MbSpacing.s3),
              MbSelectField<UnitDimension>(
                label: l10n.adminUnitDimension,
                hint: l10n.adminUnitChooseDimension,
                items: [
                  for (final d in UnitDimension.values)
                    MbSelectItem(value: d, label: _dimensionLabel(l10n, d)),
                ],
                value: _dimension,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _dimension = v),
              ),
              if (problems.contains(UnitProblem.dimensionMissing))
                Text(
                  l10n.adminUnitErrDimension,
                  style: t.caption.copyWith(color: c.priceUp),
                ),
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _factor,
                label: _dimension == null
                    ? l10n.adminUnitFactor
                    : l10n.adminUnitFactorIn(_dimension!.baseUnit),
                helper: l10n.adminUnitFactorHint,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                error: problems.contains(UnitProblem.factorInvalid)
                    ? l10n.adminUnitErrFactor
                    : null,
              ),
            ] else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.adminProductActive,
                  style: t.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l10n.adminUnitActiveHint,
                  style: t.caption.copyWith(color: c.inkMuted),
                ),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _isActive = v),
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
              label: l10n.adminCategorySave,
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
