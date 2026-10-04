import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_button.dart';
import 'unlock_cubit.dart';

enum _SheetResult { unlocked, goPro }

/// Answers a [LimitReachedFailure]: offers "watch ads" (when the free tier
/// still allows it) or Pro. Returns `true` once the server granted the
/// unlock, so the caller can retry what it was doing.
Future<bool> showUnlockSheet(
  BuildContext context,
  LimitedFeature feature,
) async {
  final result = await showModalBottomSheet<_SheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Closing mid-flow is safe: nothing is granted until the server says so.
    builder: (_) => BlocProvider(
      create: (_) => getIt<UnlockCubit>()..load(feature),
      child: const _UnlockSheet(),
    ),
  );
  if (result == _SheetResult.goPro && context.mounted) {
    await context.push(AppRoutes.billingPlans);
  }
  return result == _SheetResult.unlocked;
}

class _UnlockSheet extends StatelessWidget {
  const _UnlockSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;

    return BlocConsumer<UnlockCubit, UnlockState>(
      listenWhen: (p, n) => p.step != n.step && n.step == UnlockStep.granted,
      listener: (context, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.unlockGranted)));
        Navigator.of(context).pop(_SheetResult.unlocked);
      },
      builder: (context, state) {
        final cubit = context.read<UnlockCubit>();
        final busy =
            state.step == UnlockStep.loading ||
            state.step == UnlockStep.watching ||
            state.step == UnlockStep.verifying ||
            state.step == UnlockStep.granted;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s5,
              0,
              MbSpacing.s5,
              MbSpacing.s5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _title(context, state.feature),
                  style: t.valueMd.copyWith(color: c.ink),
                ),
                const SizedBox(height: MbSpacing.s2),
                Text(
                  _body(context, state),
                  style: t.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s5),
                if (busy)
                  _Progress(label: _progressLabel(context, state))
                else ...[
                  if (state.step == UnlockStep.failed) ...[
                    Text(
                      l10n.unlockFailed,
                      style: t.caption.copyWith(color: c.priceDown),
                    ),
                    const SizedBox(height: MbSpacing.s3),
                  ],
                  if (state.canWatchAds) ...[
                    MbButton(
                      label: l10n.watchAdsButton(
                        state.adsRequired - (state.session?.adsVerified ?? 0),
                      ),
                      block: true,
                      onPressed: cubit.watchAds,
                    ),
                    const SizedBox(height: MbSpacing.s3),
                  ],
                  MbButton(
                    label: l10n.goProNoAds,
                    variant: state.canWatchAds
                        ? MbButtonVariant.secondary
                        : MbButtonVariant.primary,
                    block: true,
                    onPressed: () =>
                        Navigator.of(context).pop(_SheetResult.goPro),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _title(BuildContext context, LimitedFeature feature) {
    final l10n = context.l10n;
    return switch (feature) {
      LimitedFeature.watchlist => l10n.unlockWatchlistTitle,
      LimitedFeature.alertRules => l10n.unlockAlertsTitle,
      LimitedFeature.proReport => l10n.unlockReportTitle,
    };
  }

  String _body(BuildContext context, UnlockState state) {
    final l10n = context.l10n;
    final entitlements = state.entitlements;
    if (entitlements != null && !entitlements.canUnlockWithAds(state.feature)) {
      return l10n.unlockLimitUsed;
    }
    if (!state.canWatchAds) return l10n.unlockProOnly;
    final slots = entitlements?.slotsPerUnlock(state.feature) ?? 1;
    return switch (state.feature) {
      LimitedFeature.watchlist => l10n.unlockWatchlistBody(slots),
      LimitedFeature.alertRules => l10n.unlockAlertsBody(slots),
      LimitedFeature.proReport => l10n.unlockReportBody,
    };
  }

  String _progressLabel(BuildContext context, UnlockState state) {
    final l10n = context.l10n;
    return switch (state.step) {
      UnlockStep.watching => l10n.unlockAdProgress(
        state.adNumber,
        state.adsRequired,
      ),
      UnlockStep.verifying => l10n.unlockVerifying,
      _ => l10n.loading,
    };
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: MbSpacing.s3),
        Text(label, style: context.mbText.body),
      ],
    );
  }
}
