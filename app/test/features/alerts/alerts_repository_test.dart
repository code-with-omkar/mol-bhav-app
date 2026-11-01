import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/alerts/data/alerts_data.dart';
import 'package:mol_bhav/features/alerts/domain/alerts.dart';
import 'package:mol_bhav/features/catalog/domain/catalog.dart';
import 'package:mol_bhav/features/opportunities/data/opportunities_data.dart';

class _MockRemote extends Mock implements AlertsRemoteDataSource {}

class _MockCatalog extends Mock implements CatalogRepository {}

class _MockCache extends Mock implements ResponseCache {}

class _MockOpportunities extends Mock
    implements OpportunitiesRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AlertsRepositoryImpl repository;
  late _MockCache cache;
  late _MockOpportunities opportunities;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    // mocktail picks the first fallback that `is` the parameter type.
    registerFallbackValue(const <String>[]);
    registerFallbackValue(Object());
  });

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    opportunities = _MockOpportunities();
    repository = AlertsRepositoryImpl(
      remote,
      _MockCatalog(),
      cache,
      opportunities,
    );
    when(() => opportunities.getOpportunities(any(), any()))
        .thenAnswer((_) async => const []);
    when(() => remote.create(any())).thenAnswer((_) async {});
    when(() => cache.read(any())).thenReturn(null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    when(() => cache.invalidate(any())).thenAnswer((_) async {});
  });

  NewAlert alert(PriceCondition condition, num value) => NewAlert(
    commodityId: 'p1',
    marketId: 'm1',
    condition: condition,
    value: value,
    push: true,
    whatsapp: false,
  );

  test('"changes by %" is sent as an either-way PriceChange rule', () async {
    final result = await repository.create(alert(PriceCondition.percent, 10));

    expect(result, isA<Ok<void>>());
    verify(
      () => remote.create({
        'productId': 'p1',
        'locationKind': 'Mandi',
        'mandiId': 'm1',
        'thresholdType': 'PriceChange',
        'thresholdPercent': 10,
      }),
    ).called(1);
  });

  test('rupee conditions stay price-level rules', () async {
    await repository.create(alert(PriceCondition.below, 1800));

    verify(
      () => remote.create({
        'productId': 'p1',
        'locationKind': 'Mandi',
        'mandiId': 'm1',
        'thresholdType': 'PriceBelow',
        'thresholdPrice': 1800,
      }),
    ).called(1);
  });

  test('a PriceChange rule reads back as priceChange', () async {
    when(() => remote.getAlertRules()).thenAnswer(
      (_) async => [
        {
          'id': 'r1',
          'product': {'name': 'Onion'},
          'thresholdType': 'PriceChange',
          'thresholdPercent': 10,
          'isActive': true,
          'createdAtUtc': '2026-10-04T10:00:00Z',
        },
      ],
    );

    final result = await repository.watchAlertRules().last;

    expect(
      (result as Ok<List<AlertRule>>).value.single.thresholdType,
      AlertThresholdType.priceChange,
    );
  });

  test(
    'a rule change drops the saved rules so the next load is live',
    () async {
      await repository.create(alert(PriceCondition.percent, 10));

      verify(
        () => cache.invalidate(
          any(that: contains(AlertsRepositoryImpl.rulesKey)),
        ),
      ).called(1);
    },
  );

  test('saved alerts are shown first, then the live list', () async {
    when(() => cache.read(AlertsRepositoryImpl.alertsKey)).thenReturn(
      CachedResponse(
        data: {
          'alerts': [_alert('a1')],
          'opportunities': const <dynamic>[],
        },
        savedAt: DateTime(2026, 10, 4),
      ),
    );
    when(() => remote.getAlerts(any(), any()))
        .thenAnswer((_) async => [_alert('a1'), _alert('a2')]);

    final results = await repository.watchAlerts(AlertFilter.all).toList();

    expect(results.map((r) => (r as Ok<List<AlertItem>>).value.length), [1, 2]);
  });

  test('opportunities join the inbox, newest first', () async {
    when(() => remote.getAlerts(any(), any()))
        .thenAnswer((_) async => [_alert('a1')]);
    when(() => opportunities.getOpportunities(any(), any()))
        .thenAnswer((_) async => [_opportunity('o1')]);

    final result = await repository.watchAlerts(AlertFilter.all).last;

    final items = (result as Ok<List<AlertItem>>).value;
    expect(items.map((a) => a.id), ['o1', 'a1']);
    final o = items.first;
    expect(o.kind, AlertKind.opportunity);
    expect(o.opportunityId, 'o1');
    expect(o.productName, 'Onion (Red)');
    expect(o.locationName, 'Lasalgaon APMC');
    expect(o.homeLocationName, 'Pune APMC');
    expect(o.percentChange, -15.83);
  });

  test('alerts still load when opportunities fail', () async {
    when(() => remote.getAlerts(any(), any()))
        .thenAnswer((_) async => [_alert('a1')]);
    when(() => opportunities.getOpportunities(any(), any()))
        .thenThrow(Exception('offline'));

    final result = await repository.watchAlerts(AlertFilter.all).last;

    expect((result as Ok<List<AlertItem>>).value.map((a) => a.id), ['a1']);
  });
}

Map<String, dynamic> _opportunity(String id) => {
  'id': id,
  'product': {
    'id': 'p1',
    'name': 'Onion',
    'defaultUnit': {'symbol': 'q'},
  },
  'variantName': 'Red',
  'home': {'locationId': 'm1', 'name': 'Pune APMC', 'price': 2400},
  'best': {
    'locationId': 'm2',
    'name': 'Lasalgaon APMC',
    'districtName': 'Nashik',
    'price': 2020,
  },
  'landedPrice': 2020,
  'savingsPercent': 15.83,
  'savingsPerUnit': 380,
  'priceDate': '2026-10-04',
  'detectedAtUtc': '2026-10-05T04:30:00Z',
  'isRead': false,
};

Map<String, dynamic> _alert(String id) => {
  'id': id,
  'product': {'name': 'Onion'},
  'thresholdType': 'PriceChange',
  'isRead': false,
  'percentChange': 12.5,
  'previousPrice': 2000,
  'newPrice': 2250,
  'triggeredAtUtc': '2026-10-04T10:00:00Z',
};
