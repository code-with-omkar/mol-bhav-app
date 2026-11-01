import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_icon.dart';
import 'app_notice_cubit.dart';

/// Covers the app while an admin has it in maintenance: the admin's message
/// and a button to check again.
class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<AppNoticeCubit>();
    return Material(
      color: c.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: MbSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MbIcon(MbIcons.settings, size: 48, color: c.inkMuted),
                const SizedBox(height: MbSpacing.s4),
                Text(
                  l10n.appNoticeMaintenanceTitle,
                  style: t.h2.copyWith(color: c.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  cubit.state.notice.message,
                  style: t.body.copyWith(color: c.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: MbSpacing.s5),
                MbButton(
                  label: l10n.appNoticeCheckAgain,
                  onPressed: cubit.load,
                  variant: MbButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
