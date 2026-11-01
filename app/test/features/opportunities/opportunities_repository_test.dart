import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/opportunities/data/opportunities_data.dart';
import 'package:mol_bhav/features/opportunities/domain/opportunities.dart';

class _MockRemote extends Mock implements OpportunitiesRemoteDataSource {}

class _MockCache extends Mock implements ResponseCache {}

void main() {
  late _MockRemote remote;
  late _MockCache cache;
  late OpportunitiesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const <String>[]);
    registerFallbackValue(Object());
  });

  setUp(() {
    remote = _MockRemote();
    cache = _MockCache();
    repository = OpportunitiesRepositoryImpl(remote, cache);
    when(() => cache.read(any())).thenReturn(null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    when(() => cache.invalidate(any())).thenAnswer((_) async {});
    when(() => remote.markRead(any())).thenAnswer((_) async {});
  });

  test('detail parses the opportunity and every market', () async {
    when(() => remote.getOpportunity('o1')).thenAnswer((_) async => _detail());

    final result = await repository.getDetail('o1');

    final detail = (result as Ok<OpportunityDetail>).value;
    expect(detail.opportunity.displayName, 'Onion (Red)');
    expect(detail.opportunity.savingsPercent, 15.83);
    expect(detail.referenceQuantity, 10);
    expect(detail.markets.map((m) => m.id), ['m2', 'm1']);
    expect(detail.markets.last.isHomeDistrict, isTrue);
  });

  test('opening an unread opportunity marks it read', () async {
    when(() => remote.getOpportunity('o1')).thenAnswer((_) async => _detail());

    await repository.getDetail('o1');
    await pumpEventQueue();

    verify(() => remote.markRead('o1')).called(1);
  });

  test('an already-read opportunity is not marked again', () async {
    when(() => remote.getOpportunity('o1'))
        .thenAnswer((_) async => _detail(isRead: true));

    await repository.getDetail('o1');
    await pumpEventQueue();

    verifyNever(() => remote.markRead(any()));
  });
}

Map<String, dynamic> _detail({bool isRead = false}) => {
  'opportunity': {
    'id': 'o1',
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
    'isRead': isRead,
  },
  'markets': [
    {
      'locationId': 'm2',
      'name': 'Lasalgaon APMC',
      'districtName': 'Nashik',
      'modalPrice': 2020,
      'landedPrice': 2020,
      'isHomeDistrict': false,
    },
    {
      'locationId': 'm1',
      'name': 'Pune APMC',
      'districtName': 'Pune',
      'modalPrice': 2400,
      'landedPrice': 2400,
      'isHomeDistrict': true,
    },
  ],
  'referenceQuantity': 10,
};
