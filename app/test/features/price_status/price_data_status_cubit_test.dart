import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/price_status/domain/price_data_status.dart';
import 'package:mol_bhav/features/price_status/presentation/price_data_status_cubit.dart';

class _MockRepository extends Mock implements PriceDataStatusRepository {}

final _updated = DateTime(2026, 10, 15, 20, 12);
final _delayed = PriceDataStatus(isDelayed: true, lastUpdatedAt: _updated);
final _fresh = PriceDataStatus(isDelayed: false, lastUpdatedAt: _updated);

void main() {
  late _MockRepository repository;
  late PriceDataStatusCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = PriceDataStatusCubit(repository);
  });

  tearDown(() => cubit.close());

  void serve(PriceDataStatus status) =>
      when(() => repository.getStatus()).thenAnswer((_) async => Ok(status));

  test('shows nothing until the server has answered', () {
    expect(cubit.state.showBanner, isFalse);
  });

  test('shows the banner when prices are delayed', () async {
    serve(_delayed);

    await cubit.load();

    expect(cubit.state.showBanner, isTrue);
    expect(cubit.state.status?.lastUpdatedAt, _updated);
  });

  test('shows nothing when prices are fresh', () async {
    serve(_fresh);

    await cubit.load();

    expect(cubit.state.showBanner, isFalse);
  });

  test(
    'closing the banner hides it, and the same problem stays closed',
    () async {
      serve(_delayed);
      await cubit.load();

      cubit.dismiss();
      expect(cubit.state.showBanner, isFalse);

      await cubit.load(); // the periodic re-check sees the same outage
      expect(cubit.state.showBanner, isFalse);
    },
  );

  test('a recovery and a later outage show the banner again', () async {
    serve(_delayed);
    await cubit.load();
    cubit.dismiss();

    serve(_fresh);
    await cubit.load();
    expect(cubit.state.showBanner, isFalse);

    serve(_delayed);
    await cubit.load();
    expect(cubit.state.showBanner, isTrue);
  });

  test('a different outage (new last-updated time) shows it again', () async {
    serve(_delayed);
    await cubit.load();
    cubit.dismiss();

    serve(
      PriceDataStatus(
        isDelayed: true,
        lastUpdatedAt: _updated.add(const Duration(days: 1)),
      ),
    );
    await cubit.load();

    expect(cubit.state.showBanner, isTrue);
  });

  test('a failed check keeps what was last known', () async {
    serve(_delayed);
    await cubit.load();

    when(() => repository.getStatus())
        .thenAnswer((_) async => const Err(NetworkFailure()));
    await cubit.load();

    expect(cubit.state.showBanner, isTrue);
  });

  test('a failed first check shows nothing', () async {
    when(() => repository.getStatus())
        .thenAnswer((_) async => const Err(NetworkFailure()));

    await cubit.load();

    expect(cubit.state.showBanner, isFalse);
  });
}
