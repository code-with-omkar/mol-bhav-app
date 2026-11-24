import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/features/tools/domain/tools.dart';
import 'package:mol_bhav/features/tools/presentation/tools_cubits.dart';

Estimate _estimate({num cost = 10000, num quantity = 100}) => Estimate(
  requirementId: 'r1',
  estimatedCost: cost,
  quantity: quantity,
  lowestPrice: 100,
  lowestSourceName: 'Hub',
  averagePrice: 110,
  savings: 1000,
  benchmarks: const [],
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  test('freight is per unit, handling is a lump sum', () {
    final landed = LandedCost.of(
      _estimate(),
      freightPerUnit: 5,
      handlingTotal: 300,
    );

    expect(landed.freight, 500);
    expect(landed.total, 10800);
    expect(landed.perUnit, 108);
    expect(landed.isExtra, isTrue);
  });

  test('without extras there is nothing to add', () {
    final landed = LandedCost.of(
      _estimate(),
      freightPerUnit: 0,
      handlingTotal: 0,
    );

    expect(landed.isExtra, isFalse);
    expect(landed.total, 10000);
  });

  test('blank, invalid or negative amounts count as 0', () {
    expect(parseExtraCost(''), 0);
    expect(parseExtraCost('abc'), 0);
    expect(parseExtraCost('-5'), 0);
    expect(parseExtraCost(' 12.5 '), 12.5);
  });

  test('a zero quantity does not divide by zero', () {
    final landed = LandedCost.of(
      _estimate(cost: 0, quantity: 0),
      freightPerUnit: 5,
      handlingTotal: 100,
    );

    expect(landed.perUnit, 0);
  });

  test('the state shows landed cost only with an estimate and an extra', () {
    const empty = CostEstimatorState();
    expect(empty.landed, isNull);

    final withEstimate = empty.copyWith(
      estimate: DataState.ready(_estimate()),
    );
    expect(withEstimate.landed, isNull);

    final withFreight = withEstimate.copyWith(freightText: '5');
    expect(withFreight.landed?.total, 10500);
  });
}
