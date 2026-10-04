import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/features/promotions/data/promotion_events_tracker.dart';
import 'package:mol_bhav/features/promotions/domain/promotions.dart';

class _MockRepository extends Mock implements PromotionsRepository {}

class _MockSession extends Mock implements SessionManager {}

/// Fallback for `captureAny()` on `addListener`: mocktail keys fallbacks by
/// runtime type, and a tear-off of a `void` function is a [VoidCallback].
void _noop() {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepository repository;
  late _MockSession session;
  late PromotionEventsTracker tracker;

  setUpAll(() {
    registerFallbackValue(<PromotionEvent>[]);
    registerFallbackValue(_noop);
  });

  setUp(() {
    repository = _MockRepository();
    session = _MockSession();
    when(() => session.hasSession).thenReturn(true);
    tracker = PromotionEventsTracker(repository, session);
    when(() => repository.recordEvents(any()))
        .thenAnswer((_) async => const Ok<void>(null));
  });

  tearDown(() => tracker.dispose());

  test('impressions wait for the batch', () {
    tracker.impression('c1');

    expect(tracker.queued, [
      const PromotionEvent('c1', PromotionEventType.impression),
    ]);
    verifyNever(() => repository.recordEvents(any()));
  });

  test('flush sends the queue once and empties it', () async {
    tracker
      ..impression('c1')
      ..impression('c2');

    await tracker.flush();

    final sent =
        verify(() => repository.recordEvents(captureAny())).captured.single
            as List<PromotionEvent>;
    expect(sent, hasLength(2));
    expect(tracker.queued, isEmpty);
  });

  test('reaching the batch size sends without waiting', () async {
    for (var i = 0; i < PromotionEventsTracker.flushAt; i++) {
      tracker.impression('c$i');
    }
    await pumpEventQueue();

    verify(() => repository.recordEvents(any())).called(1);
    expect(tracker.queued, isEmpty);
  });

  test('a click is sent straight away', () async {
    tracker.click('c1');
    await pumpEventQueue();

    verify(
      () => repository.recordEvents([
        const PromotionEvent('c1', PromotionEventType.click),
      ]),
    ).called(1);
  });

  test('a failed send is kept for the next flush', () async {
    when(() => repository.recordEvents(any()))
        .thenAnswer((_) async => const Err<void>(NetworkFailure()));
    tracker.impression('c1');

    await tracker.flush();

    expect(tracker.queued, [
      const PromotionEvent('c1', PromotionEventType.impression),
    ]);
  });

  test('the queue never grows past its cap', () async {
    when(() => repository.recordEvents(any()))
        .thenAnswer((_) async => const Err<void>(NetworkFailure()));
    for (var i = 0; i < PromotionEventsTracker.maxQueued * 2; i++) {
      tracker.impression('c$i');
      await pumpEventQueue();
    }

    expect(
      tracker.queued.length,
      lessThanOrEqualTo(PromotionEventsTracker.maxQueued),
    );
    // The newest events survive; the oldest are dropped.
    expect(
      tracker.queued.last,
      PromotionEvent(
        'c${PromotionEventsTracker.maxQueued * 2 - 1}',
        PromotionEventType.impression,
      ),
    );
  });

  test('a rejected send (4xx) is dropped, not retried', () async {
    when(
      () => repository.recordEvents(any()),
    ).thenAnswer((_) async => const Err<void>(ServerFailure(statusCode: 400)));
    tracker.impression('c1');

    await tracker.flush();

    expect(tracker.queued, isEmpty);
  });

  test('signing out drops queued events', () {
    final listener =
        verify(() => session.addListener(captureAny())).captured.single
            as VoidCallback;
    tracker.impression('c1');

    when(() => session.hasSession).thenReturn(false);
    listener();

    expect(tracker.queued, isEmpty);
  });
}
