import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/features/home/presentation/home_cubit.dart';
import 'package:mol_bhav/features/opportunities/domain/opportunities.dart';
import 'package:mol_bhav/features/watchlist/domain/watchlist.dart';

void main() {
  final now = DateTime(2026, 10, 6, 10);

  MarketOpportunity opportunity(
    String id,
    String productId, {
    num savings = 12,
    Duration age = const Duration(hours: 1),
    Duration priceAge = Duration.zero,
    num bestPrice = 1700,
  }) => MarketOpportunity(
    id: id,
    productId: productId,
    productName: 'Product $productId',
    variantName: null,
    unit: 'Quintal',
    homeId: 'home',
    homeName: 'Pune APMC',
    homePrice: 2000,
    bestId: 'best',
    bestName: 'Nashik APMC',
    bestDistrict: 'Nashik',
    bestPrice: bestPrice,
    landedPrice: 1760,
    savingsPercent: savings,
    savingsPerUnit: 240,
    priceDate: now.subtract(priceAge),
    detectedAt: now.subtract(age),
    isRead: false,
  );

  WatchlistItem watched(String productId) => WatchlistItem(
    id: 'w$productId',
    commodityId: productId,
    marketId: '',
    name: 'Product $productId',
    categoryCode: 'agriculture',
    price: 2000,
    unit: 'Quintal',
    percent: null,
    trend: const [],
  );

  test('leaves out an opportunity with no price or only an old one', () {
    final top = HomeCubit.topOpportunities(
      [
        opportunity('old', 'p1', priceAge: const Duration(days: 5)),
        opportunity('none', 'p2', bestPrice: 0),
        opportunity('good', 'p3', priceAge: const Duration(days: 2)),
      ],
      [watched('p1'), watched('p2'), watched('p3')],
      now: now,
    );

    expect(top.map((t) => t.opportunityId), ['good']);
  });
  test('keeps at most five, biggest saving first', () {
    final opportunities = [
      for (var i = 1; i <= 7; i++) opportunity('o$i', 'p$i', savings: 10 + i),
    ];
    final watchlist = [for (var i = 1; i <= 7; i++) watched('p$i')];

    final top = HomeCubit.topOpportunities(opportunities, watchlist, now: now);

    expect(top, hasLength(HomeCubit.maxTopOpportunities));
    expect(top.map((t) => t.opportunityId), ['o7', 'o6', 'o5', 'o4', 'o3']);
  });

  test('skips products no longer on the watchlist', () {
    final top = HomeCubit.topOpportunities(
      [opportunity('o1', 'p1'), opportunity('o2', 'p2')],
      [watched('p2')],
      now: now,
    );

    expect(top.map((t) => t.opportunityId), ['o2']);
  });

  test('skips opportunities older than three days', () {
    final top = HomeCubit.topOpportunities(
      [opportunity('o1', 'p1', age: const Duration(days: 4))],
      [watched('p1')],
      now: now,
    );

    expect(top, isEmpty);
  });

  test('shows only the newest opportunity per product', () {
    final top = HomeCubit.topOpportunities(
      [
        opportunity('old', 'p1', savings: 30, age: const Duration(days: 1)),
        opportunity('new', 'p1', savings: 11),
      ],
      [watched('p1')],
      now: now,
    );

    expect(top.map((t) => t.opportunityId), ['new']);
  });
}
