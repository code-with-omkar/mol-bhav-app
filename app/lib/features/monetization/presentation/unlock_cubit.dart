import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/ads/ads_config.dart';
import '../../../core/ads/rewarded_ad_player.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../account/presentation/profile_cubit.dart';
import '../domain/monetization.dart';

enum UnlockStep {
  /// Reading what can be unlocked.
  loading,

  /// "Watch N ads" (when possible) or "Go Pro".
  offer,

  /// Showing ad [UnlockState.adNumber] of [UnlockState.adsRequired].
  watching,

  /// Waiting for AdMob's signed callback to reach the server.
  verifying,

  /// The server granted the unlock; the caller retries its action.
  granted,

  /// Something went wrong; the offer can be tried again.
  failed,
}

class UnlockState extends Equatable {
  const UnlockState({
    this.step = UnlockStep.loading,
    this.feature = LimitedFeature.watchlist,
    this.entitlements,
    this.session,
    this.adNumber = 0,
    this.failure,
  });

  final UnlockStep step;
  final LimitedFeature feature;
  final Entitlements? entitlements;
  final AdUnlockSession? session;
  final int adNumber;
  final Failure? failure;

  int get adsRequired =>
      session?.adsRequired ?? entitlements?.adsPerUnlock(feature) ?? 1;

  /// Ads can be offered: supported platform, and the free limit still allows it.
  bool get canWatchAds =>
      AdsConfig.isSupported &&
      (entitlements?.canUnlockWithAds(feature) ?? false);

  UnlockState copyWith({
    UnlockStep? step,
    LimitedFeature? feature,
    Entitlements? entitlements,
    AdUnlockSession? session,
    int? adNumber,
    Failure? failure,
  }) => UnlockState(
    step: step ?? this.step,
    feature: feature ?? this.feature,
    entitlements: entitlements ?? this.entitlements,
    session: session ?? this.session,
    adNumber: adNumber ?? this.adNumber,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    step,
    feature,
    entitlements,
    session,
    adNumber,
    failure,
  ];
}

/// Runs one "watch ads to unlock" flow. The app's own "reward earned" event
/// grants nothing: after each ad it waits for the server to confirm the view
/// through AdMob's signed callback, so a tampered client cannot unlock.
@injectable
class UnlockCubit extends Cubit<UnlockState> {
  UnlockCubit(
    this._getEntitlements,
    this._start,
    this._getSession,
    this._completeWithoutAds,
    this._player,
    this._profile,
  ) : super(const UnlockState());

  final GetEntitlements _getEntitlements;
  final StartAdUnlock _start;
  final GetAdUnlockSession _getSession;
  final CompleteUnlockWithoutAds _completeWithoutAds;
  final RewardedAdPlayer _player;
  final ProfileCubit _profile;

  /// The callback usually lands within a second or two of the ad closing.
  static const _pollInterval = Duration(seconds: 1);
  static const _maxPolls = 15;

  Future<void> load(LimitedFeature feature) async {
    emit(UnlockState(feature: feature));
    final result = await _getEntitlements();
    if (isClosed) return;
    emit(switch (result) {
      Ok(value: final entitlements) => state.copyWith(
        step: UnlockStep.offer,
        entitlements: entitlements,
      ),
      // Without the numbers, still offer Pro rather than a dead end.
      Err() => state.copyWith(step: UnlockStep.offer),
    });
  }

  Future<void> watchAds() async {
    if (!state.canWatchAds) return;
    await _profile.ensureLoaded();
    final userId = _profile.state.data?.userId;
    if (userId == null || userId.isEmpty) {
      return _fail(const UnexpectedFailure());
    }

    // Reuse an open session so ads already watched still count after a retry.
    var session = state.session;
    if (session == null || !session.isOpenAt(DateTime.now())) {
      final started = await _start(state.feature);
      if (isClosed) return;
      switch (started) {
        case Err(:final failure):
          return _fail(failure);
        case Ok(:final value):
          session = value;
      }
    }

    while (!session!.isGranted) {
      emit(
        state.copyWith(
          step: UnlockStep.watching,
          session: session,
          adNumber: session.adsVerified + 1,
        ),
      );
      final outcome = await _player.play(
        userId: userId,
        customData: session.id,
      );
      if (isClosed) return;

      switch (outcome) {
        case RewardedAdOutcome.dismissed:
          emit(state.copyWith(step: UnlockStep.offer));
          return;
        case RewardedAdOutcome.failed:
          return _fail(const UnexpectedFailure());
        case RewardedAdOutcome.noFill:
          final completed = await _completeWithoutAds(session.id);
          if (isClosed) return;
          switch (completed) {
            case Err(:final failure):
              return _fail(failure);
            case Ok(:final value):
              session = value;
          }
        case RewardedAdOutcome.earned:
          emit(state.copyWith(step: UnlockStep.verifying));
          final confirmed = await _awaitVerification(session);
          if (isClosed) return;
          if (confirmed == null) return _fail(const UnexpectedFailure());
          session = confirmed;
      }
    }

    emit(state.copyWith(step: UnlockStep.granted, session: session));
  }

  /// Polls until the server has counted one more view (or granted).
  Future<AdUnlockSession?> _awaitVerification(AdUnlockSession before) async {
    for (var i = 0; i < _maxPolls; i++) {
      await Future<void>.delayed(_pollInterval);
      if (isClosed) return null;
      final result = await _getSession(before.id);
      if (result case Ok(:final value)
          when value.isGranted || value.adsVerified > before.adsVerified) {
        return value;
      }
    }
    return null;
  }

  void _fail(Failure failure) =>
      emit(state.copyWith(step: UnlockStep.failed, failure: failure));
}
