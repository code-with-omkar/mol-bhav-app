import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';

/// Stands in for a Pro-only section when the user is on Free.
class ProBanner extends StatelessWidget {
  const ProBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    return MbCard(
      child: Row(
        children: [
          MbIcon(MbIcons.lock, size: 22, color: c.accentText),
          const SizedBox(width: MbSpacing.s3),
          Expanded(
            child: Text(
              l10n.upgradeToUnlock,
              style: context.mbText.body.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(width: MbSpacing.s3),
          MbButton(
            label: l10n.seePlans,
            size: MbButtonSize.sm,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
