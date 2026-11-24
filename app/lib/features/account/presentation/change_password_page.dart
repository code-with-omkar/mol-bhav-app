import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/mb_app_bar.dart';
import '../../../shared/widgets/mb_button.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../../shared/widgets/mb_text_field.dart';
import '../domain/account.dart';
import 'change_password_cubit.dart';

/// Change the sign-in password. An account with no password yet (it signs in
/// another way) is not asked for a current one.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  Set<NewPasswordProblem> _problems = const {};
  bool _currentMissing = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<ChangePasswordCubit>();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final problems = newPasswordProblems(
      current: _current.text,
      password: _new.text,
      confirm: _confirm.text,
    );
    final currentMissing = cubit.hasPassword && _current.text.isEmpty;
    setState(() {
      _problems = problems;
      _currentMissing = currentMissing;
    });
    if (problems.isNotEmpty || currentMissing) return;

    final failure = await cubit.submit(
      currentPassword: _current.text,
      newPassword: _new.text,
    );
    if (failure == null) {
      // The cubit has signed out, so the router is already taking the user to
      // Login (and this page may be gone); the root messenger still shows it.
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(failureMessage(context, failure))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ChangePasswordCubit>();
    return Scaffold(
      appBar: MbAppBar(title: l10n.changePasswordTitle),
      body: ListView(
        padding: MbSpacing.screenPadding,
        children: [
          if (cubit.hasPassword) ...[
            MbTextField(
              controller: _current,
              label: l10n.currentPasswordLabel,
              obscureText: true,
              error: _currentMissing ? l10n.currentPasswordRequired : null,
            ),
            const SizedBox(height: 14),
          ],
          MbTextField(
            controller: _new,
            label: l10n.newPasswordLabel,
            obscureText: true,
            helper: l10n.passwordTooWeak,
            error: _problems.contains(NewPasswordProblem.tooWeak)
                ? l10n.passwordTooWeak
                : _problems.contains(NewPasswordProblem.sameAsCurrent)
                ? l10n.passwordSameAsCurrent
                : null,
          ),
          const SizedBox(height: 14),
          MbTextField(
            controller: _confirm,
            label: l10n.confirmPasswordLabel,
            obscureText: true,
            error: _problems.contains(NewPasswordProblem.mismatch)
                ? l10n.passwordsDontMatch
                : null,
          ),
          const SizedBox(height: MbSpacing.s4),
          BlocBuilder<ChangePasswordCubit, bool>(
            builder: (context, submitting) => MbButton(
              label: l10n.changePasswordAction,
              block: true,
              isLoading: submitting,
              onPressed: submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
