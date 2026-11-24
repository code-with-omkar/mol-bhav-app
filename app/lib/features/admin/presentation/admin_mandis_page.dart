import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_mandis.dart';
import 'admin_mandis_cubit.dart';

/// The mandis. Search by name or code; tap one to rename it, move it to
/// another district or switch it off; the button below adds a mandi.
class AdminMandisPage extends StatefulWidget {
  const AdminMandisPage({super.key});

  @override
  State<AdminMandisPage> createState() => _AdminMandisPageState();
}

class _AdminMandisPageState extends State<AdminMandisPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) {
        context.read<AdminMandisCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Opens the add/edit sheet once the districts are loaded.
  Future<void> _open(BuildContext context, {AdminMandi? mandi}) async {
    final cubit = context.read<AdminMandisCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await cubit.districts();
    if (!context.mounted) return;
    final districts = result.fold((failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(context, failure))),
      );
      return null;
    }, (d) => d);
    if (districts == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
      ),
      builder: (_) => _MandiSheet(
        mandi: mandi,
        districts: districts,
        onCreate: cubit.create,
        onUpdate: cubit.update,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminMandisCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminMandisTitle),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MbSpacing.s4),
          child: MbButton(
            label: l10n.adminMandiNew,
            block: true,
            onPressed: () => _open(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s4,
              MbSpacing.s3,
              MbSpacing.s4,
              0,
            ),
            child: MbTextField(
              controller: _search,
              hint: l10n.adminProductsSearchHint,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => cubit.load(search: v),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminMandisCubit, AdminMandisState>(
              builder: (context, state) {
                if (state.mandis.isEmpty) {
                  return switch (state.status) {
                    LoadStatus.failure => MbErrorView(
                      failure: state.failure!,
                      onRetry: cubit.load,
                    ),
                    LoadStatus.ready => MbEmptyView(
                      message: l10n.adminMandisEmpty,
                    ),
                    _ => const MbLoadingView(),
                  };
                }
                return RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MbSpacing.screenPadding,
                    itemCount:
                        state.mandis.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MbSpacing.s2),
                    itemBuilder: (context, i) => i >= state.mandis.length
                        ? const Padding(
                            padding: EdgeInsets.all(MbSpacing.s3),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _MandiCard(
                            mandi: state.mandis[i],
                            onTap: () => _open(context, mandi: state.mandis[i]),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MandiCard extends StatelessWidget {
  const _MandiCard({required this.mandi, required this.onTap});

  final AdminMandi mandi;
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mandi.name, style: t.title.copyWith(color: c.ink)),
                  Text(
                    '${mandi.code} · ${mandi.districtName}',
                    style: t.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
            ),
            if (!mandi.isActive)
              MbBadge(label: l10n.adminPlanOff, tone: MbBadgeTone.neutral),
          ],
        ),
      ),
    );
  }
}

/// Add or edit a mandi: its code (new only), name, district, and on/off (edit
/// only). Stays open if the save is refused, showing why.
class _MandiSheet extends StatefulWidget {
  const _MandiSheet({
    required this.mandi,
    required this.districts,
    required this.onCreate,
    required this.onUpdate,
  });

  final AdminMandi? mandi;
  final List<DistrictChoice> districts;
  final Future<Failure?> Function({
    required String code,
    required String name,
    required String districtId,
  })
  onCreate;
  final Future<Failure?> Function({
    required String id,
    required String name,
    required String districtId,
    required bool isActive,
  })
  onUpdate;

  @override
  State<_MandiSheet> createState() => _MandiSheetState();
}

class _MandiSheetState extends State<_MandiSheet> {
  final _code = TextEditingController();
  late final _name = TextEditingController(text: widget.mandi?.name ?? '');
  // A district that is no longer active is not offered; the choice stays unset
  // until one is picked.
  late String? _districtId =
      widget.districts.any((d) => d.id == widget.mandi?.districtId)
      ? widget.mandi?.districtId
      : null;
  late bool _isActive = widget.mandi?.isActive ?? true;

  bool _showErrors = false;
  bool _saving = false;
  Failure? _failure;

  bool get _isNew => widget.mandi == null;

  Set<MandiProblem> get _problems => mandiProblems(
    isNew: _isNew,
    code: _code.text,
    name: _name.text,
    districtId: _districtId,
  );

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
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
    final mandi = widget.mandi;
    final failure = mandi == null
        ? await widget.onCreate(
            code: _code.text,
            name: _name.text,
            districtId: _districtId!,
          )
        : await widget.onUpdate(
            id: mandi.id,
            name: _name.text,
            districtId: _districtId!,
            isActive: _isActive,
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
    final problems = _showErrors ? _problems : <MandiProblem>{};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MbSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isNew ? l10n.adminMandiNew : l10n.adminMandiEdit,
              style: t.title.copyWith(color: c.ink),
            ),
            if (_isNew) ...[
              const SizedBox(height: MbSpacing.s3),
              MbTextField(
                controller: _code,
                label: l10n.adminProductCode,
                helper: l10n.adminMandiCodeHint,
                enabled: !_saving,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                ],
                error: problems.contains(MandiProblem.codeInvalid)
                    ? l10n.adminProductErrCode
                    : null,
              ),
            ],
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _name,
              label: l10n.adminMandiName,
              enabled: !_saving,
              inputFormatters: [
                LengthLimitingTextInputFormatter(mandiNameMaxLength),
              ],
              error: problems.contains(MandiProblem.nameMissing)
                  ? l10n.adminMandiErrName
                  : null,
            ),
            const SizedBox(height: MbSpacing.s3),
            MbSelectField<String>(
              label: l10n.adminMandiDistrict,
              hint: l10n.adminMandiChooseDistrict,
              items: [
                for (final d in widget.districts)
                  MbSelectItem(value: d.id, label: d.label),
              ],
              value: _districtId,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _districtId = v),
            ),
            if (problems.contains(MandiProblem.districtMissing))
              Text(
                l10n.adminMandiErrDistrict,
                style: t.caption.copyWith(color: c.priceUp),
              ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.adminProductActive,
                  style: t.body.copyWith(color: c.ink),
                ),
                subtitle: Text(
                  l10n.adminMandiActiveHint,
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
