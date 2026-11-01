import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import 'app_version_cubit.dart';

/// Covers the whole app (login included) when this build is older than the
/// minimum an admin set. Admins are never covered, so a wrong minimum can
/// always be fixed from their own phone.
class UpdateGate extends StatelessWidget {
  const UpdateGate({super.key, required this.session, required this.child});

  final SessionManager session;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppVersionCubit, AppVersionState>(
      builder: (context, state) => ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final blocked = state.updateRequired && !session.isAdmin;
          return Stack(
            children: [
              child,
              if (blocked)
                Positioned.fill(child: UpdateRequiredView(state: state)),
            ],
          );
        },
      ),
    );
  }
}

/// "Please update": what is wrong, which versions are involved and a button
/// to the update link.
class UpdateRequiredView extends StatelessWidget {
  const UpdateRequiredView({super.key, required this.state});

  final AppVersionState state;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final url = state.policy.updateUrl;
    return Material(
      color: c.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: MbSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MbIcon(MbIcons.info, size: 48, color: c.inkMuted),
                const SizedBox(height: MbSpacing.s4),
                Text(
                  l10n.appVersionTitle,
                  style: t.h2.copyWith(color: c.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.appVersionBody,
                  style: t.body.copyWith(color: c.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.appVersionYours(
                    state.installed ?? '',
                    state.policy.minimumVersion ?? '',
                  ),
                  style: t.caption.copyWith(color: c.inkMuted),
                  textAlign: TextAlign.center,
                ),
                if (url != null) ...[
                  const SizedBox(height: MbSpacing.s5),
                  MbButton(
                    label: l10n.appVersionUpdate,
                    onPressed: () => _open(url),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Nothing to open it with; the page stays so the user can try again.
    }
  }
}
