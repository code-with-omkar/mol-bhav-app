import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/features/alerts/domain/alerts.dart';
import 'package:mol_bhav/features/alerts/presentation/alerts_cubits.dart';

void main() {
  AlertItem item(String id, AlertKind kind) => AlertItem(
    id: id,
    kind: kind,
    productName: 'Onion',
    percentChange: -5,
    previousPrice: 2000,
    newPrice: 1900,
    createdAt: DateTime(2026, 10, 6),
    isUnread: true,
  );

  final items = [
    item('s1', AlertKind.signal),
    item('k1', AlertKind.spike),
    item('o1', AlertKind.opportunity),
  ];

  AlertsState state(AlertFilter filter) =>
      AlertsState(filter: filter, data: DataState.ready(items));

  test('All shows every item', () {
    expect(state(AlertFilter.all).visible, hasLength(3));
  });

  test('Price signals shows drops and spikes only', () {
    expect(state(AlertFilter.signals).visible!.map((a) => a.id), ['s1', 'k1']);
  });

  test('Opportunities shows opportunities only', () {
    expect(state(AlertFilter.opportunities).visible!.map((a) => a.id), ['o1']);
  });

  test('counts every tab from the same list', () {
    final s = state(AlertFilter.all);

    expect(s.count(AlertFilter.all), 3);
    expect(s.count(AlertFilter.signals), 2);
    expect(s.count(AlertFilter.opportunities), 1);
  });

  test('nothing is visible before the first load', () {
    expect(const AlertsState().visible, isNull);
  });
}
