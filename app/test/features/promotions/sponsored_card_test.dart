import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/features/promotions/data/promotion_events_tracker.dart';
import 'package:mol_bhav/features/promotions/domain/promotions.dart';
import 'package:mol_bhav/features/promotions/presentation/sponsored_card.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/pump_app.dart';

class _MockTracker extends Mock implements PromotionEventsTracker {}

final _promotion = Promotion(
  campaignId: 'c1',
  advertiserName: 'Kisan Seeds',
  title: 'Onion seed',
  body: 'Certified seed near you.',
  ctaLabel: 'Get a quote',
  ctaUrl: Uri.parse('https://example.com/quote'),
);

void main() {
  late _MockTracker tracker;

  setUp(() {
    tracker = _MockTracker();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpApp(
    Scaffold(
      body: SingleChildScrollView(
        child: SponsoredCard(promotion: _promotion, tracker: tracker),
      ),
    ),
  );

  testWidgets('is labelled Sponsored with the advertiser', (tester) async {
    await pump(tester);

    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.text('Kisan Seeds'), findsOneWidget);
    expect(find.text('Get a quote'), findsOneWidget);
  });

  testWidgets('counts one impression however often it rebuilds', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    await pump(tester);
    await tester.pump();

    verify(() => tracker.impression('c1')).called(1);
  });

  testWidgets('the button records a click', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Get a quote'));
    await tester.pump();

    verify(() => tracker.click('c1')).called(1);
  });
}
