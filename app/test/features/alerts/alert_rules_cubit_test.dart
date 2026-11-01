import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/alerts/domain/alerts.dart';
import 'package:mol_bhav/features/alerts/presentation/alert_rules_cubit.dart';

class _MockRepository extends Mock implements AlertsRepository {}

void main() {
  late _MockRepository repository;

  AlertRule rule(String id) => AlertRule(
    id: id,
    productName: 'Onion',
    thresholdType: AlertThresholdType.priceChange,
    unit: 'q',
    isActive: true,
    createdAtUtc: DateTime(2026, 10, 5),
  );

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchAlertRules())
        .thenAnswer((_) => Stream.value(Ok([rule('r1'), rule('r2')])));
  });

  test('a deleted rule leaves the list at once', () async {
    when(() => repository.deleteAlertRule('r1'))
        .thenAnswer((_) async => const Ok(null));
    final cubit = AlertRulesCubit(repository);
    await cubit.load();

    final deleted = await cubit.deleteRule('r1');

    expect(deleted, isTrue);
    expect((cubit.state as AlertRulesLoaded).rules.map((r) => r.id), ['r2']);
    await cubit.close();
  });

  test('a failed delete keeps the rule and reports it', () async {
    when(() => repository.deleteAlertRule('r1'))
        .thenAnswer((_) async => const Err(ServerFailure()));
    final cubit = AlertRulesCubit(repository);
    await cubit.load();

    final deleted = await cubit.deleteRule('r1');

    expect(deleted, isFalse);
    expect((cubit.state as AlertRulesLoaded).rules.map((r) => r.id), [
      'r1',
      'r2',
    ]);
    await cubit.close();
  });
}
