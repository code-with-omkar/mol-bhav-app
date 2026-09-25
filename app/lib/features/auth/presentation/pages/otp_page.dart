import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_otp_input.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../cubit/otp_cubit.dart';

/// Second sign-in step: the OTP boxes, a resend countdown and verify.
class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _onStatus(BuildContext context, OtpState state) {
    switch (state.status) {
      case OtpStatus.verified:
        context.go(
          state.session!.isOnboarded
              ? AppRoutes.home
              : AppRoutes.businessProfile,
        );
      case OtpStatus.resending:
        _code.clear();
      case OtpStatus.resent:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.otpResent)));
      case OtpStatus.failure when !state.isCodeInvalid:
        showFailureSnackBar(context, state.failure!);
      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<OtpCubit>();

    return BlocConsumer<OtpCubit, OtpState>(
      listenWhen: (p, n) => p.status != n.status,
      listener: _onStatus,
      builder: (context, state) => Scaffold(
        appBar: const MbAppBar(),
        body: SingleChildScrollView(
          padding: MbSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MbPageHeading(
                title: l10n.otpTitle,
                lead: Text.rich(
                  TextSpan(
                    text: '${l10n.otpSentTo(state.challenge.mobile.display)} ',
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: MbTextLink(
                          label: l10n.otpChangeNumber,
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ],
                  ),
                  style: t.body.copyWith(color: c.inkMuted),
                ),
              ),
              const SizedBox(height: MbSpacing.s6),
              MbOtpInput(
                controller: _code,
                length: state.challenge.codeLength,
                semanticLabel: l10n.otpFieldLabel,
                hasError: state.isCodeInvalid,
                onChanged: cubit.codeChanged,
              ),
              if (state.isCodeInvalid) ...[
                const SizedBox(height: MbSpacing.s2),
                Text(
                  l10n.otpInvalid,
                  style: t.caption.copyWith(color: c.priceUp),
                ),
              ],
              const SizedBox(height: MbSpacing.s6),
              _ResendRow(state: state, onResend: cubit.resend),
              const SizedBox(height: MbSpacing.s6),
              MbButton(
                label: l10n.otpVerify,
                size: MbButtonSize.lg,
                block: true,
                isLoading: state.status == OtpStatus.verifying,
                onPressed: state.isComplete ? cubit.verify : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.state, required this.onResend});

  final OtpState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final seconds = state.secondsLeft;
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';

    return Row(
      children: [
        MbIcon(MbIcons.freshness, size: 14, color: c.inkMuted),
        const SizedBox(width: 6),
        if (seconds > 0)
          Flexible(
            child: Text(
              l10n.otpResendIn(time),
              style: context.mbText.caption.copyWith(color: c.inkMuted),
            ),
          )
        else
          MbTextLink(
            label: l10n.otpResend,
            onPressed: state.canResend ? onResend : null,
          ),
      ],
    );
  }
}
