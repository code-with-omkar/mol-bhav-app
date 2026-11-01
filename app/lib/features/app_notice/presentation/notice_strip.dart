import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_icon.dart';
import '../domain/app_notice.dart';

/// The message as a slim strip: green for a note, amber for a warning. Used by
/// the user banner and by the admin's preview.
class NoticeStrip extends StatelessWidget {
  const NoticeStrip({
    super.key,
    required this.severity,
    required this.message,
    this.onDismiss,
    this.safeTop = false,
  });

  final NoticeSeverity severity;
  final String message;

  /// Shows a close button.
  final VoidCallback? onDismiss;

  /// Keeps clear of the status bar (when the strip sits at the very top).
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final warning = severity != NoticeSeverity.info;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: warning ? c.surfaceAmber : c.surfaceGreen,
        child: SafeArea(
          top: safeTop,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MbSpacing.s4,
              vertical: MbSpacing.s2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: MbIcon(
                    warning ? MbIcons.alert : MbIcons.info,
                    size: 18,
                    color: c.ink,
                  ),
                ),
                const SizedBox(width: MbSpacing.s3),
                Expanded(
                  child: Text(
                    message,
                    style: context.mbText.body.copyWith(color: c.ink),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: l10n.appNoticeDismiss,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    onPressed: onDismiss,
                    icon: MbIcon(MbIcons.close, size: 18, color: c.ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
