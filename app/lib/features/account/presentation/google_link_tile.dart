import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/mb_dimens.dart';
import '../../../shared/widgets/google/google_sign_in_button.dart';
import '../../../shared/widgets/mb_icons.dart';
import '../../../shared/widgets/mb_panels.dart';
import '../../../shared/widgets/mb_price.dart';
import '../../../shared/widgets/mb_state_views.dart';
import '../../auth/domain/auth_failures.dart';
import '../../auth/domain/entities/login_methods.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/account.dart';
import 'profile_cubit.dart';

/// More → "Google sign-in": link Google to this account, or unlink it. Shown
/// only when the server has Google sign-in on.
class GoogleLinkTile extends StatefulWidget {
  const GoogleLinkTile({super.key, required this.profile});

  final AccountProfile profile;

  @override
  State<GoogleLinkTile> createState() => _GoogleLinkTileState();
}

class _GoogleLinkTileState extends State<GoogleLinkTile> {
  final _auth = getIt<AuthRepository>();
  LoginMethods? _methods;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _auth.getLoginMethods().then((result) {
      if (!mounted) return;
      if (result case Ok(:final value)) setState(() => _methods = value);
    });
  }

  Future<void> _run(Future<Result<void>> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        await getIt<ProfileCubit>().refresh();
      case Err(:final failure):
        _showFailure(failure);
    }
  }

  void _showFailure(Failure failure) {
    final l10n = context.l10n;
    final message = switch (failure) {
      GoogleLinkedElsewhereFailure() => l10n.googleLinkedElsewhere,
      LastSignInMethodFailure() => l10n.googleLastSignInMethod,
      GoogleTokenInvalidFailure() => l10n.googleSignInFailed,
      _ => null,
    };
    if (message == null) {
      showFailureSnackBar(context, failure);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final methods = _methods;
    if (methods == null || !methods.showGoogle) return const SizedBox.shrink();

    final profile =
        context.select<ProfileCubit, AccountProfile?>((c) => c.state.data) ??
        widget.profile;

    if (profile.hasGoogleLogin) {
      return _spaced(
        MbGroup(
          children: [
            MbListItem(
              icon: MbIcons.email,
              title: l10n.googleSignInTitle,
              subtitle: profile.googleEmail == null
                  ? l10n.googleLinked
                  : l10n.googleLinkedAs(profile.googleEmail!),
              showChevron: false,
              trailing: TextButton(
                onPressed: _busy || !profile.hasPassword
                    ? null
                    : () => _run(_auth.unlinkGoogle),
                child: Text(l10n.googleUnlinkAction),
              ),
            ),
          ],
        ),
      );
    }

    return _spaced(
      MbGroup(
        children: [
          MbListItem(
            icon: MbIcons.email,
            title: l10n.googleSignInTitle,
            subtitle: l10n.googleLinkHint,
            showChevron: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MbSpacing.s4,
              0,
              MbSpacing.s4,
              MbSpacing.s4,
            ),
            child: GoogleSignInButton(
              clientId: methods.googleClientId!,
              label: l10n.googleLinkAction,
              busy: _busy,
              onIdToken: (token) => _run(() async {
                final result = await _auth.linkGoogle(token);
                return switch (result) {
                  Ok() => const Ok<void>(null),
                  Err(:final failure) => Err<void>(failure),
                };
              }),
              onError: () => _showFailure(const GoogleTokenInvalidFailure()),
            ),
          ),
        ],
      ),
    );
  }

  /// Same gap the More page leaves between groups.
  static Widget _spaced(Widget group) =>
      Padding(padding: const EdgeInsets.only(top: 14), child: group);
}
