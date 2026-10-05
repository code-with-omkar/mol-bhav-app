import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/app_language.dart';
import '../../../../core/locale/locale_cubit.dart';
import '../../../../core/notifications/notification_service.dart';
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
import '../../domain/auth_failures.dart';
import '../../../../shared/widgets/google/google_sign_in_button.dart';
import '../cubit/google_login_cubit.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_methods_cubit.dart';
import '../cubit/password_login_cubit.dart';
import '../widgets/mobile_number_formatter.dart';

/// Sign-in with the app-language picker up front. Shows password login and/or
/// mobile OTP, whichever the server enables (`GET /auth/methods`).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.sessionExpired = false});

  /// Shown after the session could not be renewed.
  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        BlocListener<PasswordLoginCubit, PasswordLoginState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onPasswordStatus,
        ),
        BlocListener<GoogleLoginCubit, GoogleLoginState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onGoogleStatus,
        ),
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            switch (state.status) {
              case LoginStatus.codeSent:
                context.push(
                  AppRoutes.verifyOtpFrom(
                    GoRouterState.of(context).uri.queryParameters['from'],
                  ),
                  extra: state.challenge,
                );
              case LoginStatus.failure:
                showFailureSnackBar(context, state.failure!);
              case LoginStatus.editing:
              case LoginStatus.submitting:
                break;
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: MbCenteredForm(
            children: [
              const MbWordmark(size: 34, alignment: Alignment.center),
              const SizedBox(height: MbSpacing.s6),
              const _SignInOptions(),
              const SizedBox(height: MbSpacing.s6),
              const _LanguagePicker(),
              _ExpiredNotice(show: sessionExpired),
              const SizedBox(height: MbSpacing.s6),
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
    );
  }
}

void _onPasswordStatus(BuildContext context, PasswordLoginState state) {
  switch (state.status) {
    case PasswordLoginStatus.success:
      // Tells Android/iOS/the browser the login worked, so their password
      // manager offers "Save password?" (and fills it in next time).
      TextInput.finishAutofillContext();
      // Same as after OTP: token registration must not block navigation.
      unawaited(getIt<NotificationService>().initialize());
      context.go(
        state.session!.isOnboarded ? AppRoutes.home : AppRoutes.businessProfile,
      );
    case PasswordLoginStatus.failure:
      _showPasswordFailure(context, state.failure!);
    case PasswordLoginStatus.editing:
    case PasswordLoginStatus.submitting:
      break;
  }
}

void _onGoogleStatus(BuildContext context, GoogleLoginState state) {
  switch (state.status) {
    case GoogleLoginStatus.success:
      unawaited(getIt<NotificationService>().initialize());
      // Replacing the page stack also closes the mobile-number sheet.
      context.go(
        state.session!.isOnboarded ? AppRoutes.home : AppRoutes.businessProfile,
      );
    case GoogleLoginStatus.needsPhone:
      if (!state.showInvalidNumber) _askGooglePhone(context);
    case GoogleLoginStatus.failure:
      final l10n = context.l10n;
      final message = switch (state.failure) {
        AccountExistsFailure() => l10n.googleAccountExists,
        GoogleTokenInvalidFailure() => l10n.googleSignInFailed,
        _ => null,
      };
      if (message == null) {
        showFailureSnackBar(context, state.failure!);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    case GoogleLoginStatus.idle:
    case GoogleLoginStatus.submitting:
      break;
  }
}

/// New Google account: one more step for the mobile number.
Future<void> _askGooglePhone(BuildContext context) async {
  final cubit = context.read<GoogleLoginCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MbRadius.lg)),
    ),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _GooglePhoneSheet()),
  );
  // Dismissed without finishing: back to the normal login screen.
  if (!cubit.isClosed && cubit.state.status == GoogleLoginStatus.needsPhone) {
    cubit.cancel();
  }
}

class _GooglePhoneSheet extends StatelessWidget {
  const _GooglePhoneSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final t = context.mbText;
    final cubit = context.read<GoogleLoginCubit>();
    var mobile = '';

    return BlocConsumer<GoogleLoginCubit, GoogleLoginState>(
      listenWhen: (p, n) =>
          p.status != n.status && n.status == GoogleLoginStatus.failure,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(
          left: MbSpacing.s5,
          right: MbSpacing.s5,
          top: MbSpacing.s5,
          bottom: MediaQuery.of(context).viewInsets.bottom + MbSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.googlePhoneTitle, style: t.h2.copyWith(color: c.ink)),
            const SizedBox(height: 4),
            Text(
              l10n.googlePhoneSubtitle,
              style: t.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: MbSpacing.s4),
            MbTextField(
              key: const ValueKey('google-phone'),
              label: l10n.mobileNumberLabel,
              prefix: '+91',
              hint: '',
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: const [MobileNumberFormatter()],
              textInputAction: TextInputAction.done,
              error: state.showInvalidNumber ? l10n.mobileNumberInvalid : null,
              onChanged: (v) => mobile = v,
              onSubmitted: (v) => cubit.submitPhone(v),
            ),
            const SizedBox(height: MbSpacing.s4),
            MbButton(
              label: l10n.googlePhoneContinue,
              size: MbButtonSize.lg,
              block: true,
              isLoading: state.isBusy,
              onPressed: state.isBusy ? null : () => cubit.submitPhone(mobile),
            ),
          ],
        ),
      ),
    );
  }
}

/// "or" + "Continue with Google", when the server enables it.
class _GoogleSection extends StatelessWidget {
  const _GoogleSection({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mbColors;
    final cubit = context.read<GoogleLoginCubit>();
    final busy = context.select<GoogleLoginCubit, bool>((b) => b.state.isBusy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MbSpacing.s4),
        Row(
          children: [
            Expanded(child: Divider(color: c.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MbSpacing.s3),
              child: Text(
                l10n.orDivider,
                style: context.mbText.caption.copyWith(color: c.inkMuted),
              ),
            ),
            Expanded(child: Divider(color: c.border)),
          ],
        ),
        const SizedBox(height: MbSpacing.s4),
        GoogleSignInButton(
          key: const ValueKey('google-sign-in'),
          clientId: clientId,
          label: l10n.continueWithGoogle,
          busy: busy,
          onIdToken: cubit.signIn,
          onError: cubit.deviceSignInFailed,
        ),
      ],
    );
  }
}

void _showPasswordFailure(BuildContext context, Failure failure) {
  final l10n = context.l10n;
  final message = switch (failure) {
    InvalidCredentialsFailure() => l10n.invalidCredentials,
    AccountExistsFailure() => l10n.accountExists,
    _ => null,
  };
  if (message == null) {
    showFailureSnackBar(context, failure);
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Picks the card(s) for the enabled methods. With both enabled, password
/// login leads and a link switches to OTP (and back).
class _SignInOptions extends StatefulWidget {
  const _SignInOptions();

  @override
  State<_SignInOptions> createState() => _SignInOptionsState();
}

class _SignInOptionsState extends State<_SignInOptions> {
  bool _useOtp = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<LoginMethodsCubit>().state;
    final methods = state.methods;

    if (methods == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: MbSpacing.s6),
        child: MbLoadingView(),
      );
    }

    final showOtp = methods.otp && (_useOtp || !methods.password);
    final canSwitch = methods.otp && methods.password;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOtp) const _MobileCard() else const _PasswordCard(),
        if (canSwitch) ...[
          const SizedBox(height: MbSpacing.s2),
          TextButton(
            onPressed: () => setState(() => _useOtp = !_useOtp),
            child: Text(showOtp ? l10n.usePasswordInstead : l10n.useOtpInstead),
          ),
        ],
        if (methods.showGoogle)
          _GoogleSection(clientId: methods.googleClientId!),
      ],
    );
  }
}

class _PasswordCard extends StatefulWidget {
  const _PasswordCard();

  @override
  State<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<_PasswordCard> {
  bool _obscure = true;
  final _mobile = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The saved login may already be loaded when the card first builds.
    _applyPrefill(context.read<PasswordLoginCubit>().state);
  }

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  void _applyPrefill(PasswordLoginState state) {
    if (state.prefillSeq == 0) return;
    _mobile.value = const MobileNumberFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: state.mobile),
    );
    _password.text = state.password;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mbColors;
    final t = context.mbText;
    final l10n = context.l10n;
    final cubit = context.read<PasswordLoginCubit>();

    return BlocConsumer<PasswordLoginCubit, PasswordLoginState>(
      listenWhen: (p, n) => p.prefillSeq != n.prefillSeq,
      listener: (_, state) => _applyPrefill(state),
      builder: (context, state) {
        final register = state.isRegister;
        final passwordError = switch (state.passwordIssue) {
          PasswordIssue.empty => l10n.passwordRequired,
          PasswordIssue.tooWeak => l10n.passwordTooWeak,
          _ => null,
        };

        void submit() {
          FocusScope.of(context).unfocus();
          cubit.submit();
        }

        final visibilityToggle = IconButton(
          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: c.inkMuted,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        );

        return MbCard(
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    register ? l10n.registerTitle : l10n.loginTitle,
                    style: t.h1.copyWith(
                      fontSize: 20,
                      height: 28 / 20,
                      color: c.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  register ? l10n.registerSubtitle : l10n.passwordLoginSubtitle,
                  style: t.caption.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: MbSpacing.s4),
                MbTextField(
                  key: const ValueKey('password-login-mobile'),
                  controller: _mobile,
                  label: l10n.mobileNumberLabel,
                  prefix: '+91',
                  hint: '',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: const [MobileNumberFormatter()],
                  textInputAction: TextInputAction.next,
                  error: state.showInvalidNumber
                      ? l10n.mobileNumberInvalid
                      : null,
                  onChanged: cubit.mobileChanged,
                ),
                const SizedBox(height: MbSpacing.s3),
                MbTextField(
                  key: const ValueKey('password-login-password'),
                  controller: _password,
                  label: l10n.passwordLabel,
                  hint: '',
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: [
                    if (register)
                      AutofillHints.newPassword
                    else
                      AutofillHints.password,
                  ],
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      PasswordLoginState.maxLength,
                    ),
                  ],
                  textInputAction: register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  error: passwordError,
                  helper: register && passwordError == null
                      ? l10n.passwordTooWeak
                      : null,
                  trailing: visibilityToggle,
                  onChanged: cubit.passwordChanged,
                  onSubmitted: register ? null : (_) => submit(),
                ),
                if (register) ...[
                  const SizedBox(height: MbSpacing.s3),
                  MbTextField(
                    key: const ValueKey('password-login-confirm'),
                    label: l10n.confirmPasswordLabel,
                    hint: '',
                    obscureText: _obscure,
                    keyboardType: TextInputType.visiblePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        PasswordLoginState.maxLength,
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    error: state.passwordIssue == PasswordIssue.mismatch
                        ? l10n.passwordsDoNotMatch
                        : null,
                    onChanged: cubit.confirmPasswordChanged,
                    onSubmitted: (_) => submit(),
                  ),
                ],
                if (state.canSavePassword)
                  Padding(
                    padding: const EdgeInsets.only(top: MbSpacing.s2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.savePasswordLabel,
                                style: t.body.copyWith(color: c.ink),
                              ),
                              Text(
                                l10n.savePasswordHint,
                                style: t.caption.copyWith(color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const ValueKey('password-login-save'),
                          value: state.savePassword,
                          onChanged:
                              state.status == PasswordLoginStatus.submitting
                              ? null
                              : cubit.savePasswordChanged,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: MbSpacing.s4),
                MbButton(
                  label: register ? l10n.createAccountAction : l10n.loginAction,
                  size: MbButtonSize.lg,
                  block: true,
                  isLoading: state.status == PasswordLoginStatus.submitting,
                  onPressed: submit,
                ),
                const SizedBox(height: MbSpacing.s2),
                TextButton(
                  onPressed: state.status == PasswordLoginStatus.submitting
                      ? null
                      : cubit.toggleMode,
                  child: Text(
                    register ? l10n.switchToLogin : l10n.switchToRegister,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              hint: '',
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
