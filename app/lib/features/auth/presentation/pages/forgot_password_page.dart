import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/mb_dimens.dart';
import '../../../../shared/widgets/mb_app_bar.dart';
import '../../../../shared/widgets/mb_button.dart';
import '../../../../shared/widgets/mb_state_views.dart';
import '../../../../shared/widgets/mb_text_field.dart';
import '../../../account/domain/account.dart';
import '../../domain/entities/mobile_number.dart';
import '../cubit/forgot_password_cubit.dart';
import '../widgets/mobile_number_formatter.dart';

/// Enter the mobile number, get a code, set a new password. The password
/// manager is told about the new password so it can update what it saved.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _mobile = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _numberInvalid = false;
  bool _codeMissing = false;
  Set<NewPasswordProblem> _problems = const {};

  @override
  void dispose() {
    _mobile.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send() async {
    final cubit = context.read<ForgotPasswordCubit>();
    final mobile = cubit.state.sentTo ?? MobileNumber.tryParse(_mobile.text);
    setState(() => _numberInvalid = mobile == null);
    if (mobile == null) return;
    final failure = await cubit.sendCode(mobile);
    if (!mounted || failure == null) return;
    _say(failureMessage(context, failure));
  }

  Future<void> _reset() async {
    final cubit = context.read<ForgotPasswordCubit>();
    final problems = newPasswordProblems(
      current: '',
      password: _password.text,
      confirm: _confirm.text,
    );
    final codeMissing = _code.text.trim().isEmpty;
    setState(() {
      _problems = problems;
      _codeMissing = codeMissing;
    });
    if (problems.isNotEmpty || codeMissing) return;

    final failure = await cubit.reset(
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (failure != null) {
      _say(failureMessage(context, failure));
      return;
    }
    // Lets the phone's password manager offer to update the saved password.
    TextInput.finishAutofillContext();
    _say(context.l10n.passwordChanged);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    return Scaffold(
      appBar: MbAppBar(
        title: l10n.forgotPasswordTitle,
        onBack: () => context.go(AppRoutes.login),
      ),
      body: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
        builder: (context, state) {
          final sentTo = state.sentTo;
          return AutofillGroup(
            // Saving is asked for only after the server accepts the password.
            onDisposeAction: AutofillContextAction.cancel,
            child: ListView(
              padding: MbSpacing.screenPadding,
              children: [
                Text(
                  sentTo == null
                      ? l10n.forgotPasswordIntro
                      : l10n.forgotPasswordSent(sentTo.display),
                  style: t.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s4),
                if (sentTo == null) ...[
                  MbTextField(
                    key: const ValueKey('forgot-mobile'),
                    controller: _mobile,
                    label: l10n.mobileNumberLabel,
                    prefix: '+91',
                    keyboardType: TextInputType.phone,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: const [MobileNumberFormatter()],
                    error: _numberInvalid ? l10n.mobileNumberInvalid : null,
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: MbSpacing.s4),
                  MbButton(
                    label: l10n.forgotPasswordSendCode,
                    block: true,
                    isLoading: state.busy,
                    onPressed: state.busy ? null : _send,
                  ),
                ] else ...[
                  MbTextField(
                    key: const ValueKey('forgot-code'),
                    controller: _code,
                    label: l10n.forgotPasswordCode,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    error: _codeMissing
                        ? l10n.forgotPasswordCodeRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                  MbTextField(
                    key: const ValueKey('forgot-password'),
                    controller: _password,
                    label: l10n.newPasswordLabel,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    helper: l10n.passwordTooWeak,
                    error: _problems.contains(NewPasswordProblem.tooWeak)
                        ? l10n.passwordTooWeak
                        : null,
                  ),
                  const SizedBox(height: 14),
                  MbTextField(
                    key: const ValueKey('forgot-confirm'),
                    controller: _confirm,
                    label: l10n.confirmPasswordLabel,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    error: _problems.contains(NewPasswordProblem.mismatch)
                        ? l10n.passwordsDontMatch
                        : null,
                  ),
                  const SizedBox(height: MbSpacing.s4),
                  MbButton(
                    label: l10n.forgotPasswordReset,
                    block: true,
                    isLoading: state.busy,
                    onPressed: state.busy ? null : _reset,
                  ),
                  const SizedBox(height: MbSpacing.s2),
                  TextButton(
                    onPressed: state.busy ? null : _send,
                    child: Text(l10n.forgotPasswordResend),
                  ),
                  TextButton(
                    onPressed: state.busy
                        ? null
                        : context.read<ForgotPasswordCubit>().changeNumber,
                    child: Text(l10n.forgotPasswordChangeNumber),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
