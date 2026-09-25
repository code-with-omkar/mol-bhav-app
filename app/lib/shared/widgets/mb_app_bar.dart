import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import 'mb_icon_button.dart';
import 'mb_icons.dart';

class MbAppBarAction {
  const MbAppBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final MbIcons icon;
  final String label;
  final VoidCallback? onPressed;
}

/// Top bar for inner screens: back arrow, title, up to two icon actions.
/// Sits on `surface`, no shadow. The back arrow shows when the route can pop
/// or [onBack] is given.
class MbAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MbAppBar({
    super.key,
    this.title,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
  });

  final String? title;
  final VoidCallback? onBack;
  final bool showBack;
  final List<MbAppBarAction> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final back = showBack && (onBack != null || canPop);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: c.surface,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                if (back)
                  MbIconButton(
                    icon: MbIcons.back,
                    label: context.l10n.back,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                SizedBox(width: back ? 8 : 4),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title ?? '',
                      style: context.mbText.appBarTitle.copyWith(color: c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                for (final action in actions)
                  MbIconButton(
                    icon: action.icon,
                    label: action.label,
                    onPressed: action.onPressed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
