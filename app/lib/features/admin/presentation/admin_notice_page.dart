import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../core/utils/statuses.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../../app_notice/domain/app_notice.dart';
import '../../app_notice/presentation/notice_strip.dart';
import 'admin_notice_cubit.dart';

/// The longest message the API accepts.
const _maxLength = 280;

/// Edit the one message every user sees: switch it on or off, pick its type
/// (note, warning, or a maintenance page that blocks the app) and write it.
class AdminNoticePage extends StatelessWidget {
  const AdminNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminNoticeCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminNoticeTitle),
      body: BlocConsumer<AdminNoticeCubit, AdminNoticeState>(
        listenWhen: (a, b) => b.saves > a.saves || b.saveFailure != null,
        listener: (context, state) {
          final failure = state.saveFailure;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failure == null
                    ? l10n.adminNoticeSaved
                    : failureMessage(context, failure),
              ),
            ),
          );
          if (failure != null) cubit.failureShown();
        },
        builder: (context, state) {
          final notice = state.notice.data;
          if (notice == null) {
            return state.notice.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.notice.failure!,
                    onRetry: cubit.load,
                  )
                : const MbLoadingView();
          }
          return _Form(initial: notice, saving: state.saving);
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.initial, required this.saving});

  final AppNotice initial;
  final bool saving;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _message = TextEditingController(
    text: widget.initial.message,
  );
  late bool _active = widget.initial.isActive;
  late NoticeSeverity _severity = widget.initial.severity;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  AppNotice get _draft => AppNotice(
    isActive: _active,
    severity: _severity,
    message: _message.text.trim(),
  );

  /// An empty message is fine only while the notice is off.
  bool get _canSave =>
      !widget.saving && (!_active || _draft.message.isNotEmpty);

  String _label(NoticeSeverity s) {
    final l10n = context.l10n;
    return switch (s) {
      NoticeSeverity.info => l10n.adminNoticeInfo,
      NoticeSeverity.warning => l10n.adminNoticeWarning,
      NoticeSeverity.maintenance => l10n.adminNoticeMaintenance,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final text = _message.text.trim();
    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        Text(l10n.adminNoticeIntro, style: t.body.copyWith(color: c.inkMuted)),
        const SizedBox(height: MbSpacing.s3),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.adminNoticeShow,
            style: t.title.copyWith(color: c.ink),
          ),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
        const SizedBox(height: MbSpacing.s2),
        Text(l10n.adminNoticeType, style: t.title.copyWith(color: c.ink)),
        const SizedBox(height: MbSpacing.s2),
        Wrap(
          spacing: MbSpacing.s2,
          children: [
            for (final s in NoticeSeverity.values)
              ChoiceChip(
                label: Text(_label(s)),
                selected: _severity == s,
                onSelected: (_) => setState(() => _severity = s),
              ),
          ],
        ),
        if (_severity == NoticeSeverity.maintenance) ...[
          const SizedBox(height: MbSpacing.s2),
          Text(
            l10n.adminNoticeMaintenanceHint,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
        ],
        const SizedBox(height: MbSpacing.s4),
        MbTextField(
          controller: _message,
          label: l10n.adminNoticeMessage,
          hint: l10n.adminNoticeMessageHint,
          minLines: 3,
          maxLines: 5,
          inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
          helper: '${_message.text.length}/$_maxLength',
          onChanged: (_) => setState(() {}),
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: MbSpacing.s4),
          Text(l10n.adminNoticePreview, style: t.title.copyWith(color: c.ink)),
          const SizedBox(height: MbSpacing.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(MbRadius.md),
            child: NoticeStrip(severity: _severity, message: text),
          ),
        ],
        const SizedBox(height: MbSpacing.s5),
        MbButton(
          label: l10n.adminNoticeSave,
          block: true,
          isLoading: widget.saving,
          onPressed: _canSave
              ? () => context.read<AdminNoticeCubit>().save(_draft)
              : null,
        ),
        if (_active && text.isEmpty) ...[
          const SizedBox(height: MbSpacing.s2),
          Text(
            l10n.adminNoticeMessageRequired,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
        ],
      ],
    );
  }
}
