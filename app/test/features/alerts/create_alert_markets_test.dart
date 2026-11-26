import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/account/domain/account.dart';
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart';
import 'package:mol_bhav/features/alerts/domain/alerts.dart';
import 'package:mol_bhav/features/alerts/presentation/alerts_cubits.dart';
import 'package:mol_bhav/core/utils/data_state.dart';

class _MockRepository extends Mock implements AlertsRepository {}

class _MockProfile extends Mock implements ProfileCubit {}

const _options = AlertOptions(
  products: [
    AlertProduct(id: 'p1', name: 'Onion', categoryCode: 'agri', unit: 'qtl'),
  ],
  states: [
    AlertState(id: 'ka', name: 'Karnataka'),
    AlertState(id: 'mh', name: 'Maharashtra'),
  ],
);

AlertMarket _market(String id, String state) =>
    AlertMarket(id: id, name: id, stateName: state);

void main() {
  late _MockRepository repository;
  late CreateAlertCubit cubit;

  setUp(() {
    repository = _MockRepository();
    final profile = _MockProfile();
    when(profile.ensureLoaded).thenAnswer((_) async {});
    when(() => profile.state).thenReturn(const DataState<AccountProfile>());
    when(repository.getOptions).thenAnswer((_) async => const Ok(_options));
    when(() => repository.getMarkets('ka'))
        .thenAnswer((_) async => Ok([_market('hubli', 'Karnataka')]));
    when(() => repository.getMarkets('mh')).thenAnswer(
      (_) async => Ok([
        _market('nagpur', 'Maharashtra'),
        _market('pune', 'Maharashtra'),
      ]),
    );
    when(() => repository.getCurrentPrice(any(), any())).thenAnswer(
      (_) async => const Ok(
        CurrentPrice(
          marketName: 'pune',
          price: 1000,
          unit: 'qtl',
          stateName: 'Maharashtra',
        ),
      ),
    );
    cubit = CreateAlertCubit(
      GetAlertOptions(repository),
      GetAlertMarkets(repository),
      GetCurrentPrice(repository),
      CreateAlert(repository),
      profile,
    );
  });

  tearDown(() => cubit.close());

  test('only one state\'s markets are loaded', () async {
    await cubit.load();

    expect(cubit.state.stateId, 'ka');
    expect(cubit.state.marketId, 'hubli');
    verifyNever(() => repository.getMarkets('mh'));
  });

  test('a market passed in opens its own state and stays selected', () async {
    await cubit.load(commodityId: 'p1', marketId: 'pune');

    expect(cubit.state.stateId, 'mh');
    expect(cubit.state.marketId, 'pune');
  });

  test('choosing another state picks its first market', () async {
    await cubit.load();
    await cubit.selectState('mh');

    expect(cubit.state.markets, hasLength(2));
    expect(cubit.state.marketId, 'nagpur');
    expect(cubit.state.loadingMarkets, isFalse);
  });
}
