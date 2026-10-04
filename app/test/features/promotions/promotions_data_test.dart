import 'package:flutter_test/flutter_test.dart';
import 'package:mol_bhav/features/promotions/data/promotions_data.dart';
import 'package:mol_bhav/features/promotions/domain/promotions.dart';

Map<String, dynamic> _json({
  String ctaUrl = 'https://example.com/quote',
  String? imageUrl,
}) => {
  'campaignId': 'c1',
  'advertiserName': 'Kisan Seeds',
  'title': 'Onion seed',
  'body': 'Certified seed near you.',
  'ctaLabel': 'Get a quote',
  'ctaUrl': ctaUrl,
  'imageUrl': imageUrl,
};

void main() {
  test('parses an https promotion', () {
    final p = PromotionsRepositoryImpl.parsePromotion(
      _json(imageUrl: 'https://cdn.example.com/a.png'),
    );

    expect(p, isNotNull);
    expect(p!.ctaUrl, Uri.parse('https://example.com/quote'));
    expect(p.imageUrl, Uri.parse('https://cdn.example.com/a.png'));
  });

  test('drops a promotion whose link is not https', () {
    const urls = ['http://example.com', 'javascript:alert(1)', 'tel:123'];
    for (final url in urls) {
      expect(
        PromotionsRepositoryImpl.parsePromotion(_json(ctaUrl: url)),
        isNull,
      );
    }
  });

  test('ignores a non-https image but keeps the card', () {
    final p = PromotionsRepositoryImpl.parsePromotion(
      _json(imageUrl: 'http://cdn.example.com/a.png'),
    );

    expect(p, isNotNull);
    expect(p!.imageUrl, isNull);
  });

  test('placements use the API names', () {
    expect(
      PromotionPlacement.values.map(PromotionsRepositoryImpl.placementName),
      ['HomeFeed', 'MandiPrices', 'MarketComparison'],
    );
  });
}
