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
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_states.dart';
import 'admin_states_cubit.dart';

/// The states with their districts. Tap one to rename it or switch it off; add
/// a district from its state's card, or a state with the button below.
class AdminStatesPage extends StatelessWidget {
  const AdminStatesPage({super.key});

  Future<void> _open(
    BuildContext context, {
    required String title,
    required bool isNew,
    bool needsCode = false,
    String name = '',
    bool isActive = true,
    required Future<Failure?> Function(String name, String code, bool isActive)
    onSave,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) => _PlaceSheet(
      title: title,
      isNew: isNew,
      needsCode: needsCode,
      name: name,
      isActive: isActive,
      onSave: onSave,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<AdminStatesCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminStatesTitle),
      body: BlocBuilder<AdminStatesCubit, DataState<List<AdminState>>>(
        builder: (context, state) {
          final states = state.data;
          if (states == null) {
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
                  l10n.adminStatesIntro,
                  style: context.mbText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s3),
                if (states.isEmpty)
                  MbEmptyView(message: l10n.adminStatesEmpty)
                else
                  for (final s in states) ...[
                    _StateCard(
                      state: s,
                      onEdit: () => _open(
                        context,
                        title: l10n.adminStateEdit,
                        isNew: false,
                        name: s.name,
                        isActive: s.isActive,
                        onSave: (name, _, active) =>
                            cubit.updateState(s.id, name, active),
                      ),
                      onAddDistrict: () => _open(
                        context,
                        title: l10n.adminDistrictNew,
                        isNew: true,
                        onSave: (name, _, _) => cubit.addDistrict(s.id, name),
                      ),
                      onEditDistrict: (d) => _open(
                        context,
                        title: l10n.adminDistrictEdit,
                        isNew: false,
                        name: d.name,
                        isActive: d.isActive,
                        onSave: (name, _, active) =>
                            cubit.updateDistrict(s.id, d.id, name, active),
                      ),
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
            label: l10n.adminStateNew,
            block: true,
            onPressed: () => _open(
              context,
              title: l10n.adminStateNew,
              isNew: true,
              needsCode: true,
              onSave: (name, code, _) => cubit.createState(name, code),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.state,
    required this.onEdit,
    required this.onAddDistrict,
    required this.onEditDistrict,
  });

  final AdminState state;
  final VoidCallback onEdit;
  final VoidCallback onAddDistrict;
  final void Function(AdminDistrict district) onEditDistrict;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.name, style: t.title.copyWith(color: c.ink)),
                      Text(
                        state.code,
                        style: t.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (!state.isActive)
                  MbBadge(label: l10n.adminPlanOff, tone: MbBadgeTone.neutral),
              ],
            ),
          ),
          for (final d in state.districts)
            InkWell(
              onTap: () => onEditDistrict(d),
              child: Padding(
                padding: const EdgeInsets.only(top: MbSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '› ${d.name}',
                        style: t.body.copyWith(color: c.ink),
                      ),
                    ),
                    if (!d.isActive)
                      MbBadge(
                        label: l10n.adminPlanOff,
                        tone: MbBadgeTone.neutral,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: MbSpacing.s2),
          MbButton(
            label: l10n.adminDistrictNew,
            variant: MbButtonVariant.secondary,
            onPressed: onAddDistrict,
          ),
        ],
      ),
    );
  }
}

/// Add or edit a state or district: its name, the code (a new state only), and
/// on/off (edit only). Stays open if the save is refused, showing why.
class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({
    required this.title,
    required this.isNew,
    required this.needsCode,
    required this.name,
    required this.isActive,
    required this.onSave,
  });

  final String title;
  final bool isNew;
  final bool needsCode;
  final String name;
  final bool isActive;
  final Future<Failure?> Function(String name, String code, bool isActive)
  onSave;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late final _name = TextEditingController(text: widget.name);
  final _code = TextEditingController();
  late bool _isActive = widget.isActive;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  Set<PlaceProblem> get _problems => placeProblems(
    name: _name.text,
    needsCode: widget.needsCode,
    code: _code.text,
  );

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
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
    final failure = await widget.onSave(_name.text, _code.text, _isActive);
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
    final problems = _showErrors ? _problems : <PlaceProblem>{};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: t.title.copyWith(color: c.ink)),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _name,
              label: l10n.adminMandiName,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(stateNameMaxLength),
              ],
              error: problems.contains(PlaceProblem.nameMissing)
                  ? l10n.adminPlaceErrName
                  : null,
            ),
            if (widget.needsCode) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _code,
                label: l10n.adminProductCode,
                helper: l10n.adminStateCodeHint,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(stateCodeMaxLength),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                error: problems.contains(PlaceProblem.codeInvalid)
                    ? l10n.adminStateErrCode
                    : null,
              ),
            ],
            if (!widget.isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.adminProductActive,
                  style: t.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l10n.adminPlaceActiveHint,
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
