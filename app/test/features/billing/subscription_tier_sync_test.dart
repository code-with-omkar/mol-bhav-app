import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/core/session/token_renewal.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/features/account/domain/account.dart';
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart';
import 'package:mol_bhav/features/billing/presentation/subscription_tier_sync.dart';

class _MockProfile extends Mock implements ProfileCubit {}

class _MockTokens extends Mock implements TokenRenewal {}

class _MockSession extends Mock implements SessionManager {}

AccountProfile _profileWith({required bool isPro}) => AccountProfile(
  name: 'Ramesh',
  phoneNumberMasked: '******3210',
  userId: 'u1',
  businessTypeName: 'Trader',
  districtName: 'Pune',
  stateName: 'Maharashtra',
  categoryCodes: const [],
  categoryNames: const [],
  isPro: isPro,
  pushEnabled: true,
  whatsappEnabled: false,
);

void main() {
  late _MockProfile profile;
  late _MockTokens tokens;
  late _MockSession session;
  late DataState<AccountProfile> current;
  late DateTime now;
  late bool serverSaysPro;

  SubscriptionTierSync build() =>
      SubscriptionTierSync(profile, tokens, session, clock: () => now);

  setUp(() {
    profile = _MockProfile();
    tokens = _MockTokens();
    session = _MockSession();
    now = DateTime(2026, 10, 3, 10);
    serverSaysPro = false;
    current = DataState.ready(_profileWith(isPro: true));

    when(() => session.hasSession).thenReturn(true);
    when(() => profile.state).thenAnswer((_) => current);
    when(() => profile.refresh()).thenAnswer((_) async {
      current = DataState.ready(_profileWith(isPro: serverSaysPro));
    });
    when(() => tokens.renewNow()).thenAnswer((_) async {});
  });

  test(
    'Pro turned Free on the server: refreshes the profile and renews the token',
    () async {
      await build().recheck();

      verify(() => profile.refresh()).called(1);
      verify(() => tokens.renewNow()).called(1);
    },
  );

  test('still Pro after the refresh: the token is left alone', () async {
    serverSaysPro = true;

    await build().recheck();

    verify(() => profile.refresh()).called(1);
    verifyNever(() => tokens.renewNow());
  });

  test('a Free user is never rechecked', () async {
    current = DataState.ready(_profileWith(isPro: false));

    await build().recheck();

    verifyNever(() => profile.refresh());
    verifyNever(() => tokens.renewNow());
  });

  test('signed out: nothing happens', () async {
    when(() => session.hasSession).thenReturn(false);

    await build().recheck();

    verifyNever(() => profile.refresh());
  });

  test('repeated resumes within the interval hit the server once', () async {
    serverSaysPro = true;
    final sync = build();

    await sync.recheck();
    now = now.add(const Duration(minutes: 1));
    await sync.recheck();

    verify(() => profile.refresh()).called(1);
  });

  test('a resume after the interval checks again', () async {
    serverSaysPro = true;
    final sync = build();

    await sync.recheck();
    now = now.add(const Duration(minutes: 6));
    await sync.recheck();

    verify(() => profile.refresh()).called(2);
  });
}
