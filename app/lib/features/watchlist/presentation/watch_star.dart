import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mb_icon_button.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../monetization/presentation/unlock_sheet.dart';
import '../domain/watchlist.dart';
import 'watchlist_cubit.dart';

/// Adds or removes a product (or one variant) and reports the outcome. When
/// the free watchlist is full it offers the unlock sheet and, once unlocked,
/// adds the item after all.
Future<void> toggleWatch(
  BuildContext context,
  String productId, {
  String? variantId,
}) async {
  final cubit = context.read<WatchlistCubit>();
  final removing = cubit.state.itemFor(productId, variantId: variantId);
  var result = await cubit.toggle(productId, variantId: variantId);
  if (!context.mounted) return;

  if (result case Err(failure: LimitReachedFailure(:final feature))) {
    final unlocked = await showUnlockSheet(context, feature);
    if (!unlocked || !context.mounted) return;
    result = await cubit.toggle(productId, variantId: variantId);
    if (!context.mounted) return;
  }

  showWatchlistResult(context, result, removed: removing);
}

/// Snackbar after a watchlist change. After a removal it offers Undo, which
/// adds the item back.
void showWatchlistResult(
  BuildContext context,
  Result<void> result, {
  WatchlistItem? removed,
}) {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  switch (result) {
    case Err(failure: AlreadyWatchedFailure()):
      messenger.showSnackBar(SnackBar(content: Text(l10n.alreadyInWatchlist)));
    case Err(:final failure):
      showFailureSnackBar(context, failure);
    case Ok() when removed != null:
      final cubit = context.read<WatchlistCubit>();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.removedFromWatchlist(removed.name)),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () =>
                cubit.add(removed.commodityId, variantId: removed.variantId),
          ),
        ),
      );
    case Ok():
      messenger.showSnackBar(SnackBar(content: Text(l10n.addedToWatchlist)));
  }
}

/// Star that is filled while the product/variant is on the watchlist.
class WatchStarButton extends StatelessWidget {
  const WatchStarButton({super.key, required this.productId, this.variantId});

  final String productId;
  final String? variantId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final watched = context.select<WatchlistCubit, bool>(
      (c) => c.state.itemFor(productId, variantId: variantId) != null,
    );
    return MbIconButton(
      icon: MbIcons.watchlist,
      label: watched ? l10n.removeFromWatchlist : l10n.addToWatchlist,
      filled: watched,
      color: watched ? context.mbColors.bhavAmber : context.mbColors.inkMuted,
      onPressed: () => toggleWatch(context, productId, variantId: variantId),
    );
  }
}
