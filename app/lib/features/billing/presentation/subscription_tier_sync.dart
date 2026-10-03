import '../../../core/session/session_manager.dart';
import '../../../core/session/token_renewal.dart';
import '../../account/presentation/profile_cubit.dart';

/// Notices a lapsed Pro subscription while the app is open.
///
/// The server expires subscriptions on a schedule and flips the user's tier, but a running app only learns
/// that when it next fetches the profile, and the API keeps reading the old tier from the access token until
/// that is renewed. [recheck] (called when the app returns to the foreground) refetches the profile and, when
/// Pro has turned into Free, renews the token so the API gate drops Pro too.
///
/// Free users are skipped: an upgrade always goes through checkout, which refreshes both itself.
class SubscriptionTierSync {
  SubscriptionTierSync(
    this._profile,
    this._tokens,
    this._session, {
    this._minInterval = const Duration(minutes: 5),
    this._clock = DateTime.now,
  });

  final ProfileCubit _profile;
  final TokenRenewal _tokens;
  final SessionManager _session;
  final Duration _minInterval;
  final DateTime Function() _clock;

  DateTime? _lastCheck;
  bool _running = false;

  Future<void> recheck() async {
    if (_running || !_session.hasSession) return;
    final wasPro = _profile.state.data?.isPro ?? false;
    if (!wasPro) return;

    final now = _clock();
    final last = _lastCheck;
    if (last != null && now.difference(last) < _minInterval) return;

    _running = true;
    _lastCheck = now;
    try {
      await _profile.refresh();
      final isPro = _profile.state.data?.isPro ?? false;
      if (!isPro) await _tokens.renewNow();
    } finally {
      _running = false;
    }
  }
}
