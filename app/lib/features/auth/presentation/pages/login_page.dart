import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/brand.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/app_language.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_chip_group.dart';
import '../../../../shared/widgets/mb_icon.dart';
import '../../../../shared/widgets/mb_layout.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../../../shared/widgets/mb_text_field.dart';
import '../../../../shared/widgets/mb_wordmark.dart';
import '../cubit/login_cubit.dart';
import '../widgets/mobile_number_formatter.dart';

/// Mobile-number sign-in with the app-language picker up front.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.sessionExpired = false});

  /// Shown after the session could not be renewed.
  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.codeSent:
            context.push(AppRoutes.verifyOtp, extra: state.challenge);
          case LoginStatus.failure:
            showFailureSnackBar(context, state.failure!);
          case LoginStatus.editing:
          case LoginStatus.submitting:
            break;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MbSpacing.s4,
                  48,
                  MbSpacing.s4,
                  MbSpacing.s4,
                ),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MbWordmark(size: 34),
                          const SizedBox(height: MbSpacing.s4),
                          Text(
                            Brand.taglineHi,
                            style: t.taglineHi.copyWith(
                              fontSize: 20,
                              height: 30 / 20,
                              color: c.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.taglineTranslation,
                            style: t.body.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: MbSpacing.s6),
                      const _MobileCard(),
                      const SizedBox(height: MbSpacing.s6),
                      const _LanguagePicker(),
                      _ExpiredNotice(show: sessionExpired),
                      const SizedBox(height: MbSpacing.s6),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MbIcon(MbIcons.shield, size: 14, color: c.inkMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.loginPrivacyNote,
                              textAlign: TextAlign.center,
                              style: t.caption.copyWith(color: c.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard();

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<LoginCubit>();

    return MbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.loginTitle,
              style: t.h1.copyWith(fontSize: 20, height: 28 / 20, color: c.ink),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.loginSubtitle,
            style: t.caption.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: MbSpacing.s4),
          BlocBuilder<LoginCubit, LoginState>(
            buildWhen: (p, n) => p.showInvalidNumber != n.showInvalidNumber,
            builder: (context, state) => MbTextField(
              label: l10n.mobileNumberLabel,
              prefix: '+91',
              hint: l10n.mobileNumberHint,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: const [MobileNumberFormatter()],
              textInputAction: TextInputAction.done,
              error: state.showInvalidNumber ? l10n.mobileNumberInvalid : null,
              onChanged: cubit.mobileChanged,
              onSubmitted: (_) => cubit.submit(),
            ),
          ),
          const SizedBox(height: MbSpacing.s4),
          BlocBuilder<LoginCubit, LoginState>(
            buildWhen: (p, n) => p.status != n.status,
            builder: (context, state) => MbButton(
              label: l10n.sendOtp,
              size: MbButtonSize.lg,
              block: true,
              isLoading: state.status == LoginStatus.submitting,
              onPressed: () {
                FocusScope.of(context).unfocus();
                cubit.submit();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final l10n = context.l10n;
    final language = context.watch<LocaleCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MbIcon(MbIcons.language, size: 16, color: c.ink),
            const SizedBox(width: 6),
            Text(
              l10n.appLanguage,
              style: context.mbText.fieldLabel.copyWith(color: c.ink),
            ),
          ],
        ),
        const SizedBox(height: MbSpacing.s2),
        MbChipGroup<AppLanguage>.single(
          semanticLabel: l10n.appLanguage,
          value: language,
          onChanged: (next) {
            HapticFeedback.selectionClick();
            context.read<LocaleCubit>().select(next);
          },
          options: [
            for (final option in AppLanguage.values)
              MbChipOption(value: option, label: option.nativeName),
          ],
        ),
      ],
    );
  }
}

/// Tells the user once why they are back on Login.
class _ExpiredNotice extends StatefulWidget {
  const _ExpiredNotice({required this.show});

  final bool show;

  @override
  State<_ExpiredNotice> createState() => _ExpiredNoticeState();
}

class _ExpiredNoticeState extends State<_ExpiredNotice> {
  @override
  void initState() {
    super.initState();
    if (!widget.show) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.errorSession)));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
