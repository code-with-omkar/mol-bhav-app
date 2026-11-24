import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_field_frame.dart';
import '../../../shared/widgets/mb_layout.dart';
import '../../../shared/widgets/mb_multi_select_field.dart';
import '../../../shared/widgets/mb_select_field.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/admin_ads.dart';
import '../domain/admin_campaigns.dart';
import 'admin_campaign_form_cubit.dart';
import 'admin_campaign_list_page.dart';

/// Create a campaign, or edit one (and activate, pause or end it). A new one
/// starts as a draft: it does not show until it is activated. An ended
/// campaign is final, so its form is read-only.
class AdminCampaignFormPage extends StatefulWidget {
  const AdminCampaignFormPage({super.key, this.campaign});

  /// The campaign being edited; null to create one.
  final AdminCampaign? campaign;

  @override
  State<AdminCampaignFormPage> createState() => _AdminCampaignFormPageState();
}

class _AdminCampaignFormPageState extends State<AdminCampaignFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _cta;
  late final TextEditingController _url;
  late final TextEditingController _image;
  late final TextEditingController _priority;
  late final TextEditingController _cap;

  /// Problems are shown only after a save was tried, not while typing.
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    // Created now, not on first use: the page can be left before the form shows.
    final draft = context.read<AdminCampaignFormCubit>().state.draft;
    _name = TextEditingController(text: draft.name);
    _title = TextEditingController(text: draft.title);
    _body = TextEditingController(text: draft.body);
    _cta = TextEditingController(text: draft.ctaLabel);
    _url = TextEditingController(text: draft.ctaUrl);
    _image = TextEditingController(text: draft.imageUrl);
    _priority = TextEditingController(text: draft.priority);
    _cap = TextEditingController(text: draft.dailyCap);
  }

  bool get _editing => widget.campaign != null;

  bool get _locked => widget.campaign?.isEnded ?? false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _title,
      _body,
      _cta,
      _url,
      _image,
      _priority,
      _cap,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  AdminCampaignFormCubit get _cubit => context.read<AdminCampaignFormCubit>();

  void _edit(CampaignDraft Function(CampaignDraft d) change) =>
      _cubit.edit(change(_cubit.state.draft));

  Future<void> _pickDate({required bool start}) async {
    final draft = _cubit.state.draft;
    final now = DateTime.now();
    final current = (start ? draft.startsOn : draft.endsOn) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    _edit(
      (d) => start
          ? d.copyWith(startsOn: () => picked)
          : d.copyWith(endsOn: () => picked),
    );
  }

  Future<void> _addAdvertiser() async {
    final result = await showDialog<_NewAdvertiser>(
      context: context,
      builder: (_) => const _AdvertiserDialog(),
    );
    if (result == null || !mounted) return;
    await _cubit.addAdvertiser(
      name: result.name,
      contactName: result.contactName,
      contactPhone: result.contactPhone,
      gstin: result.gstin,
    );
  }

  Future<void> _act(CampaignAction action) async {
    if (action == CampaignAction.end) {
      final l10n = context.l10n;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.adminCampaignEndTitle),
          content: Text(l10n.adminCampaignEndBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.adminCampaignEndConfirm),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }
    await _cubit.setStatus(action);
  }

  void _save() {
    if (campaignProblems(_cubit.state.draft).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    _cubit.save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: MbAppBar(
        title: _editing ? l10n.adminCampaignEditTitle : l10n.adminCampaignsNew,
      ),
      body: BlocConsumer<AdminCampaignFormCubit, AdminCampaignFormState>(
        listenWhen: (a, b) =>
            b.failure != null || b.outcome != CampaignFormOutcome.none,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.failure != null) {
            messenger.showSnackBar(
              SnackBar(content: Text(failureMessage(context, state.failure!))),
            );
            _cubit.failureShown();
            return;
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                state.outcome == CampaignFormOutcome.created
                    ? l10n.adminCampaignCreated
                    : l10n.adminNoticeSaved,
              ),
            ),
          );
          // Tell the list something changed, so it reloads.
          Navigator.of(context).pop(true);
        },
        builder: (context, state) {
          final setup = state.setup.data;
          if (setup == null) {
            return state.setup.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.setup.failure!,
                    onRetry: () => _cubit.load(campaign: widget.campaign),
                  )
                : const MbLoadingView();
          }
          return _form(context, state, setup);
        },
      ),
    );
  }

  Widget _form(
    BuildContext context,
    AdminCampaignFormState state,
    CampaignFormSetup setup,
  ) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final draft = state.draft;
    final problems = _showErrors
        ? campaignProblems(draft)
        : <CampaignProblem>{};
    final enabled = !_locked && !state.busy;
    final day = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    String? err(CampaignProblem p, String message) =>
        problems.contains(p) ? message : null;

    List<TextInputFormatter> limit(int n) => [
      LengthLimitingTextInputFormatter(n),
    ];

    final categoryByName = {for (final c in setup.categories) c.name: c.code};
    final stateByName = {for (final s in setup.states) s.name: s.id};
    final campaign = widget.campaign;

    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        if (_locked) ...[
          Text(
            l10n.adminCampaignEndedNote,
            style: t.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s3),
        ],
        if (campaign != null && !campaign.targetsFitForm) ...[
          Text(
            l10n.adminCampaignTargetsReset,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s3),
        ],
        MbSelectField<String>(
          label: l10n.adminCampaignAdvertiser,
          hint: l10n.adminCampaignChooseAdvertiser,
          error: err(
            CampaignProblem.advertiserMissing,
            l10n.adminCampaignErrRequired,
          ),
          items: [
            for (final a in setup.advertisers)
              MbSelectItem(value: a.id, label: a.name),
          ],
          value: draft.advertiserId,
          // A campaign keeps its advertiser.
          onChanged: enabled && !_editing
              ? (id) => _edit((d) => d.copyWith(advertiserId: () => id))
              : null,
        ),
        if (!_editing)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: enabled ? _addAdvertiser : null,
              child: Text(l10n.adminCampaignAddAdvertiser),
            ),
          ),
        const SizedBox(height: MbSpacing.s2),
        MbTextField(
          controller: _name,
          label: l10n.adminCampaignName,
          enabled: enabled,
          inputFormatters: limit(CampaignLimits.name),
          error: err(
            CampaignProblem.nameInvalid,
            l10n.adminCampaignErrRequired,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(name: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbSelectField<AdPlacement>(
          label: l10n.adminCampaignPlacement,
          items: [
            for (final p in AdPlacement.values)
              MbSelectItem(value: p, label: adPlacementLabel(l10n, p)),
          ],
          value: draft.placement,
          onChanged: enabled
              ? (p) => _edit((d) => d.copyWith(placement: p))
              : null,
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(l10n.adminCampaignAdTitle, style: t.title.copyWith(color: c.ink)),
        const SizedBox(height: MbSpacing.s2),
        MbTextField(
          controller: _title,
          label: l10n.adminCampaignHeadline,
          enabled: enabled,
          inputFormatters: limit(CampaignLimits.title),
          helper: '${draft.title.length}/${CampaignLimits.title}',
          error: err(
            CampaignProblem.titleInvalid,
            l10n.adminCampaignErrRequired,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(title: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _body,
          label: l10n.adminCampaignText,
          enabled: enabled,
          minLines: 2,
          maxLines: 4,
          inputFormatters: limit(CampaignLimits.body),
          helper: '${draft.body.length}/${CampaignLimits.body}',
          error: err(
            CampaignProblem.bodyInvalid,
            l10n.adminCampaignErrRequired,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(body: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _cta,
          label: l10n.adminCampaignButton,
          enabled: enabled,
          inputFormatters: limit(CampaignLimits.ctaLabel),
          helper: '${draft.ctaLabel.length}/${CampaignLimits.ctaLabel}',
          error: err(
            CampaignProblem.ctaLabelInvalid,
            l10n.adminCampaignErrRequired,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(ctaLabel: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _url,
          label: l10n.adminCampaignLink,
          hint: 'https://',
          enabled: enabled,
          keyboardType: TextInputType.url,
          error: err(CampaignProblem.ctaUrlInvalid, l10n.adminCampaignErrLink),
          onChanged: (v) => _edit((d) => d.copyWith(ctaUrl: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _image,
          label: l10n.adminCampaignImage,
          hint: 'https://',
          enabled: enabled,
          keyboardType: TextInputType.url,
          error: err(
            CampaignProblem.imageUrlInvalid,
            l10n.adminCampaignErrLink,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(imageUrl: v)),
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(
          l10n.adminCampaignWhenTitle,
          style: t.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: MbSpacing.s2),
        MbFieldFrame(
          label: l10n.adminCampaignStarts,
          error: err(
            CampaignProblem.startMissing,
            l10n.adminCampaignErrRequired,
          ),
          onTap: enabled ? () => _pickDate(start: true) : null,
          child: Text(
            draft.startsOn == null
                ? l10n.adminCampaignPickDate
                : day.format(draft.startsOn!),
            style: t.fieldInput.copyWith(
              color: draft.startsOn == null ? c.inkMuted : c.ink,
            ),
          ),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbFieldFrame(
          label: l10n.adminCampaignEnds,
          error:
              err(CampaignProblem.endMissing, l10n.adminCampaignErrRequired) ??
              err(CampaignProblem.endBeforeStart, l10n.adminCampaignErrDates),
          onTap: enabled ? () => _pickDate(start: false) : null,
          child: Text(
            draft.endsOn == null
                ? l10n.adminCampaignPickDate
                : day.format(draft.endsOn!),
            style: t.fieldInput.copyWith(
              color: draft.endsOn == null ? c.inkMuted : c.ink,
            ),
          ),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _priority,
          label: l10n.adminCampaignPriority,
          helper: l10n.adminCampaignPriorityHint,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          error: err(
            CampaignProblem.priorityInvalid,
            l10n.adminCampaignErrPriority,
          ),
          onChanged: (v) => _edit((d) => d.copyWith(priority: v)),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _cap,
          label: l10n.adminCampaignCap,
          helper: l10n.adminCampaignCapHint,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          error: err(CampaignProblem.dailyCapInvalid, l10n.adminCampaignErrCap),
          onChanged: (v) => _edit((d) => d.copyWith(dailyCap: v)),
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(
          l10n.adminCampaignAudienceTitle,
          style: t.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: MbSpacing.s2),
        MbMultiSelectField(
          label: l10n.adminCampaignCategories,
          emptyLabel: l10n.adminCampaignChooseCategories,
          options: categoryByName.keys.toList(),
          selected: {
            for (final e in categoryByName.entries)
              if (draft.categoryCodes.contains(e.value)) e.key,
          },
          enabled: enabled,
          onChanged: (names) => _edit(
            (d) => d.copyWith(
              categoryCodes: {for (final n in names) categoryByName[n]!},
            ),
          ),
        ),
        if (problems.contains(CampaignProblem.categoriesMissing))
          Padding(
            padding: const EdgeInsets.only(top: MbSpacing.s1),
            child: Text(
              l10n.adminCampaignErrCategories,
              style: t.caption.copyWith(color: c.priceUp),
            ),
          ),
        const SizedBox(height: MbSpacing.s3),
        MbMultiSelectField(
          label: l10n.adminCampaignStates,
          options: stateByName.keys.toList(),
          selected: {
            for (final e in stateByName.entries)
              if (draft.stateIds.contains(e.value)) e.key,
          },
          enabled: enabled,
          onChanged: (names) => _edit(
            (d) =>
                d.copyWith(stateIds: {for (final n in names) stateByName[n]!}),
          ),
        ),
        const SizedBox(height: MbSpacing.s4),
        Text(l10n.adminCampaignPreview, style: t.title.copyWith(color: c.ink)),
        const SizedBox(height: MbSpacing.s2),
        _Preview(draft: draft, advertisers: setup.advertisers),
        if (campaign != null && !_locked) ...[
          const SizedBox(height: MbSpacing.s4),
          Text(
            l10n.adminCampaignStatusTitle(
              campaignStateLabel(l10n, campaign.status),
            ),
            style: t.title.copyWith(color: c.ink),
          ),
          const SizedBox(height: MbSpacing.s2),
          Wrap(
            spacing: MbSpacing.s2,
            runSpacing: MbSpacing.s2,
            children: [
              if (campaign.status != CampaignState.active)
                MbButton(
                  label: l10n.adminCampaignActivate,
                  variant: MbButtonVariant.secondary,
                  onPressed: state.busy
                      ? null
                      : () => _act(CampaignAction.activate),
                ),
              if (campaign.status == CampaignState.active)
                MbButton(
                  label: l10n.adminCampaignPause,
                  variant: MbButtonVariant.secondary,
                  onPressed: state.busy
                      ? null
                      : () => _act(CampaignAction.pause),
                ),
              MbButton(
                label: l10n.adminCampaignEnd,
                variant: MbButtonVariant.secondary,
                onPressed: state.busy ? null : () => _act(CampaignAction.end),
              ),
            ],
          ),
        ],
        if (!_locked) ...[
          const SizedBox(height: MbSpacing.s5),
          MbButton(
            label: l10n.adminCampaignSave,
            block: true,
            isLoading: state.busy,
            onPressed: state.busy ? null : _save,
          ),
        ],
        const SizedBox(height: MbSpacing.s4),
      ],
    );
  }
}

/// A rough picture of the card users will see (not the real thing, which
/// would count a view).
class _Preview extends StatelessWidget {
  const _Preview({required this.draft, required this.advertisers});

  final CampaignDraft draft;
  final List<AdminAdvertiser> advertisers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final advertiser = advertisers
        .where((a) => a.id == draft.advertiserId)
        .firstOrNull;
    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [l10n.promotionSponsored, ?advertiser?.name].join(' · '),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s1),
          Text(
            draft.title.trim().isEmpty
                ? l10n.adminCampaignHeadline
                : draft.title,
            style: t.title.copyWith(
              color: draft.title.trim().isEmpty ? c.inkMuted : c.ink,
            ),
          ),
          const SizedBox(height: MbSpacing.s1),
          Text(
            draft.body.trim().isEmpty ? l10n.adminCampaignText : draft.body,
            style: t.body.copyWith(
              color: draft.body.trim().isEmpty ? c.inkMuted : c.ink,
            ),
          ),
          const SizedBox(height: MbSpacing.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                draft.ctaLabel.trim().isEmpty
                    ? l10n.adminCampaignButton
                    : draft.ctaLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewAdvertiser {
  const _NewAdvertiser({
    required this.name,
    this.contactName,
    this.contactPhone,
    this.gstin,
  });

  final String name;
  final String? contactName;
  final String? contactPhone;
  final String? gstin;
}

/// Asks for a new advertiser's details. Only the business name is required.
class _AdvertiserDialog extends StatefulWidget {
  const _AdvertiserDialog();

  @override
  State<_AdvertiserDialog> createState() => _AdvertiserDialogState();
}

class _AdvertiserDialogState extends State<_AdvertiserDialog> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _gstin = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      (_gstin.text.trim().isEmpty ||
          _gstin.text.trim().length == CampaignLimits.gstinLength);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.adminAdvertiserTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MbTextField(
              controller: _name,
              label: l10n.adminAdvertiserName,
              inputFormatters: [
                LengthLimitingTextInputFormatter(CampaignLimits.advertiserName),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _contact,
              label: l10n.adminAdvertiserContact,
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _phone,
              label: l10n.adminAdvertiserPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: MbSpacing.s3),
            MbTextField(
              controller: _gstin,
              label: l10n.adminAdvertiserGst,
              inputFormatters: [
                LengthLimitingTextInputFormatter(CampaignLimits.gstinLength),
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        TextButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(
                  _NewAdvertiser(
                    name: _name.text.trim(),
                    contactName: _contact.text,
                    contactPhone: _phone.text,
                    gstin: _gstin.text.toUpperCase(),
                  ),
                )
              : null,
          child: Text(l10n.adminAdvertiserSave),
        ),
      ],
    );
  }
}
