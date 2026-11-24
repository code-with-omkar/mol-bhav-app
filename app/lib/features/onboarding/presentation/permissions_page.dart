import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/first_run_permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../../../shared/widgets/mb_layout.dart';

/// Shown once, right after the app is installed and opened: what the app would
/// like to use and why, then the system prompts. Skipping is allowed.
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    // The router moves on when this finishes, so there is nothing to reset.
    await getIt<FirstRunPermissions>().allow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: MbSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(l10n.permissionsTitle, style: t.h2.copyWith(color: c.ink)),
              const SizedBox(height: MbSpacing.s2),
              Text(
                l10n.permissionsIntro,
                style: t.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: MbSpacing.s4),
              _Reason(
                icon: MbIcons.alert,
                title: l10n.permissionsNotificationsTitle,
                body: l10n.permissionsNotificationsBody,
              ),
              const SizedBox(height: MbSpacing.s3),
              _Reason(
                icon: MbIcons.market,
                title: l10n.permissionsLocationTitle,
                body: l10n.permissionsLocationBody,
              ),
              const Spacer(),
              MbButton(
                label: l10n.permissionsAllow,
                block: true,
                isLoading: _busy,
                onPressed: _busy ? null : _allow,
              ),
              const SizedBox(height: MbSpacing.s2),
              TextButton(
                onPressed: _busy ? null : getIt<FirstRunPermissions>().finish,
                child: Text(l10n.permissionsNotNow),
              ),
              Text(
                l10n.permissionsChangeLater,
                textAlign: TextAlign.center,
                style: t.caption.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.title, required this.body});

  final MbIcons icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    return MbCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MbIcon(icon, size: 22, color: c.ink),
          const SizedBox(width: MbSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.title.copyWith(color: c.ink)),
                const SizedBox(height: MbSpacing.s1),
                Text(body, style: t.caption.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
