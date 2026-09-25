import 'package:flutter/material.dart';

import '../../core/error/failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/mb_dimens.dart';
import 'mb_button.dart';
import 'mb_icon.dart';

/// Localised, user-facing text for a [Failure].
String failureMessage(BuildContext context, Failure failure) {
  final l10n = context.l10n;
  return switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorSession,
    ServerFailure(:final message) => message ?? l10n.errorServer,
    _ => l10n.errorUnexpected,
  };
}

class MbLoadingView extends StatelessWidget {
  const MbLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.l10n.loading,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// Full-area error with a retry action.
class MbErrorView extends StatelessWidget {
  const MbErrorView({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: MbIcons.info,
      message: failureMessage(context, failure),
      action: MbButton(
        label: context.l10n.retry,
        icon: MbIcons.refresh,
        variant: MbButtonVariant.secondary,
        onPressed: onRetry,
      ),
    );
  }
}

class MbEmptyView extends StatelessWidget {
  const MbEmptyView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: MbIcons.info,
      message: message,
      action: onRetry == null
          ? null
          : MbButton(
              label: context.l10n.retry,
              icon: MbIcons.refresh,
              variant: MbButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message, this.action});

  final MbIcons icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MbSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MbIcon(icon, color: c.inkMuted),
            const SizedBox(height: MbSpacing.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.mbText.body.copyWith(color: c.inkMuted),
            ),
            if (action != null) ...[
              const SizedBox(height: MbSpacing.s4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows [failure] as a snackbar (for errors after a user action).
void showFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failureMessage(context, failure))));
}
