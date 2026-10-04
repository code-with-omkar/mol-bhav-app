import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/ads/rewarded_ad_player.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/features/account/domain/account.dart';
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart';
import 'package:mol_bhav/features/monetization/domain/monetization.dart';
import 'package:mol_bhav/features/monetization/presentation/unlock_cubit.dart';

class _MockGetEntitlements extends Mock implements GetEntitlements {}

class _MockStartAdUnlock extends Mock implements StartAdUnlock {}

class _MockGetAdUnlockSession extends Mock implements GetAdUnlockSession {}

class _MockCompleteUnlockWithoutAds extends Mock
    implements CompleteUnlockWithoutAds {}

class _MockRewardedAdPlayer extends Mock implements RewardedAdPlayer {}

class _MockProfileCubit extends MockCubit<DataState<AccountProfile>>
    implements ProfileCubit {}

const _slots = SlotEntitlement(
  used: 10,
  limit: 10,
  maximum: 25,
  slotsPerUnlock: 5,
  adsPerUnlock: 1,
  canUnlockWithAds: true,
);

const _entitlements = Entitlements(
  isPro: false,
  watchlist: _slots,
  alertRules: _slots,
  reports: ReportEntitlement(
    availableUnlocks: 0,
    unlocksLeftToday: 2,
    adsPerUnlock: 2,
    canUnlockWithAds: true,
  ),
);

AdUnlockSession _session({int verified = 0, bool granted = false}) =>
    AdUnlockSession(
      id: 's1',
      feature: LimitedFeature.watchlist,
      adsRequired: 1,
      adsVerified: verified,
      status: granted ? AdUnlockStatus.granted : AdUnlockStatus.pending,
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

const _profile = AccountProfile(
  name: 'Omkar',
  phoneNumberMasked: '******3210',
  userId: 'u1',
  businessTypeName: 'Caterer',
  districtName: 'Pune',
  stateName: 'Maharashtra',
  categoryCodes: ['agriculture'],
  categoryNames: ['Agriculture'],
  isPro: false,
  pushEnabled: true,
  whatsappEnabled: true,
);

void main() {
  late _MockGetEntitlements getEntitlements;
  late _MockStartAdUnlock start;
  late _MockGetAdUnlockSession getSession;
  late _MockCompleteUnlockWithoutAds noFill;
  late _MockRewardedAdPlayer player;
  late _MockProfileCubit profile;

  setUpAll(() => registerFallbackValue(LimitedFeature.watchlist));

  setUp(() {
    getEntitlements = _MockGetEntitlements();
    start = _MockStartAdUnlock();
    getSession = _MockGetAdUnlockSession();
    noFill = _MockCompleteUnlockWithoutAds();
    player = _MockRewardedAdPlayer();
    profile = _MockProfileCubit();

    when(() => getEntitlements())
        .thenAnswer((_) async => const Ok(_entitlements));
    when(() => start(any())).thenAnswer((_) async => Ok(_session()));
    when(() => profile.ensureLoaded()).thenAnswer((_) async {});
    when(() => profile.state).thenReturn(const DataState.ready(_profile));
  });

  UnlockCubit build() =>
      UnlockCubit(getEntitlements, start, getSession, noFill, player, profile);

  test('offers ads once the entitlements are loaded', () async {
    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);

    expect(cubit.state.step, UnlockStep.offer);
    expect(cubit.state.canWatchAds, isTrue);
    await cubit.close();
  });

  test('still offers Pro when the entitlements cannot be read', () async {
    when(() => getEntitlements())
        .thenAnswer((_) async => const Err(NetworkFailure()));
    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);

    expect(cubit.state.step, UnlockStep.offer);
    expect(cubit.state.canWatchAds, isFalse);
    await cubit.close();
  });

  test('grants only after the server confirms the watched ad', () async {
    when(() => player.play(userId: 'u1', customData: 's1'))
        .thenAnswer((_) async => RewardedAdOutcome.earned);
    when(() => getSession('s1'))
        .thenAnswer((_) async => Ok(_session(verified: 1, granted: true)));

    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);
    await cubit.watchAds();

    expect(cubit.state.step, UnlockStep.granted);
    verify(() => getSession('s1')).called(1);
    await cubit.close();
  });

  test('falls back to the no-ad grant when no ad can be loaded', () async {
    when(() => player.play(userId: 'u1', customData: 's1'))
        .thenAnswer((_) async => RewardedAdOutcome.noFill);
    when(() => noFill('s1'))
        .thenAnswer((_) async => Ok(_session(granted: true)));

    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);
    await cubit.watchAds();

    expect(cubit.state.step, UnlockStep.granted);
    verifyNever(() => getSession(any()));
    await cubit.close();
  });

  test('returns to the offer when the ad is closed early', () async {
    when(() => player.play(userId: 'u1', customData: 's1'))
        .thenAnswer((_) async => RewardedAdOutcome.dismissed);

    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);
    await cubit.watchAds();

    expect(cubit.state.step, UnlockStep.offer);
    expect(cubit.state.session?.id, 's1');
    verifyNever(() => noFill(any()));
    await cubit.close();
  });

  test('fails when the server rejects the unlock', () async {
    when(() => start(any()))
        .thenAnswer((_) async => const Err(ServerFailure(statusCode: 403)));

    final cubit = build();
    await cubit.load(LimitedFeature.watchlist);
    await cubit.watchAds();

    expect(cubit.state.step, UnlockStep.failed);
    expect(cubit.state.failure, const ServerFailure(statusCode: 403));
    await cubit.close();
  });
}
