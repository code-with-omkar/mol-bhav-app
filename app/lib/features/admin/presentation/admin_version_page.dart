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
import '../../app_version/domain/app_version.dart';
import '../../app_version/presentation/app_version_cubit.dart';
import 'admin_version_cubit.dart';

/// Same rule the API applies: up to three dotted numbers, or empty for none.
final _versionPattern = RegExp(r'^\d{1,6}(\.\d{1,6}){0,2}$');

/// Set the oldest app version that may still run. Older builds show an
/// "update required" page with the update link. Admins are never blocked.
class AdminVersionPage extends StatelessWidget {
  const AdminVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<AdminVersionCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.adminVersionTitle),
      body: BlocConsumer<AdminVersionCubit, AdminVersionState>(
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
          final policy = state.policy.data;
          if (policy == null) {
            return state.policy.status == LoadStatus.failure
                ? MbErrorView(
                    failure: state.policy.failure!,
                    onRetry: cubit.load,
                  )
                : const MbLoadingView();
          }
          return _Form(initial: policy, saving: state.saving);
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.initial, required this.saving});

  final AppVersionPolicy initial;
  final bool saving;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _version = TextEditingController(
    text: widget.initial.minimumVersion ?? '',
  );
  late final TextEditingController _link = TextEditingController(
    text: widget.initial.updateUrl ?? '',
  );

  @override
  void dispose() {
    _version.dispose();
    _link.dispose();
    super.dispose();
  }

  bool get _versionOk {
    final v = _version.text.trim();
    return v.isEmpty || _versionPattern.hasMatch(v);
  }

  bool get _linkOk {
    final v = _link.text.trim();
    if (v.isEmpty) return true;
    final uri = Uri.tryParse(v);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  bool get _canSave => !widget.saving && _versionOk && _linkOk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final mine = context.select((AppVersionCubit v) => v.state.installed);
    return ListView(
      padding: MbSpacing.screenPadding,
      children: [
        Text(l10n.adminVersionIntro, style: t.body.copyWith(color: c.inkMuted)),
        if (mine != null) ...[
          const SizedBox(height: MbSpacing.s2),
          Text(
            l10n.adminVersionThisApp(mine),
            style: t.caption.copyWith(color: c.inkMuted),
          ),
        ],
        const SizedBox(height: MbSpacing.s4),
        MbTextField(
          controller: _version,
          label: l10n.adminVersionMinimum,
          hint: '1.2.0',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          error: _versionOk ? null : l10n.adminVersionInvalid,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: MbSpacing.s3),
        MbTextField(
          controller: _link,
          label: l10n.adminVersionLink,
          hint: 'https://',
          keyboardType: TextInputType.url,
          error: _linkOk ? null : l10n.adminVersionLinkInvalid,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: MbSpacing.s5),
        MbButton(
          label: l10n.adminNoticeSave,
          block: true,
          isLoading: widget.saving,
          onPressed: _canSave
              ? () => context.read<AdminVersionCubit>().save(
                  AppVersionPolicy(
                    minimumVersion: _version.text.trim().isEmpty
                        ? null
                        : _version.text.trim(),
                    updateUrl: _link.text.trim().isEmpty
                        ? null
                        : _link.text.trim(),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
