import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/session/session_manager.dart';
import '../domain/promotions.dart';

/// Batches sponsored-card impressions and clicks into few requests: flushes
/// once [flushAt] events are queued, [flushAfter] after the first one, or when
/// the app goes to the background. A send that failed for a transient reason
/// (offline, 5xx, 429) is put back (oldest dropped past [maxQueued]) and goes
/// with the next flush; anything else is dropped — counts are best-effort and
/// the server caps them anyway. Signing out drops the queue, so one account's
/// events never go out under the next.
@lazySingleton
class PromotionEventsTracker {
  PromotionEventsTracker(this._repository, this._session) {
    _session.addListener(_onSession);
  }

  final PromotionsRepository _repository;
  final SessionManager _session;

  static const flushAt = 20;
  static const maxQueued = 50;
  static const flushAfter = Duration(seconds: 30);

  final List<PromotionEvent> _queue = [];
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _sending = false;

  @visibleForTesting
  List<PromotionEvent> get queued => List.unmodifiable(_queue);

  void impression(String campaignId) =>
      _add(PromotionEvent(campaignId, PromotionEventType.impression));

  void click(String campaignId) {
    _add(PromotionEvent(campaignId, PromotionEventType.click));
    // The tap usually sends the user out of the app: don't wait for the timer.
    unawaited(flush());
  }

  void _add(PromotionEvent event) {
    _lifecycle ??= AppLifecycleListener(onHide: () => unawaited(flush()));
    _queue.add(event);
    if (_queue.length > maxQueued) {
      _queue.removeRange(0, _queue.length - maxQueued);
    }
    if (_queue.length >= flushAt) {
      unawaited(flush());
    } else {
      _timer ??= Timer(flushAfter, () => unawaited(flush()));
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_sending || _queue.isEmpty) return;
    _sending = true;
    final batch = List<PromotionEvent>.of(_queue);
    _queue.clear();
    try {
      final result = await _repository.recordEvents(batch);
      final retry = switch (result) {
        // Signed out while sending: the batch belongs to the old account.
        Err<void>(:final failure) =>
          _session.hasSession && _isTransient(failure),
        Ok<void>() => false,
      };
      if (retry) {
        _queue.insertAll(0, batch);
        if (_queue.length > maxQueued) {
          _queue.removeRange(0, _queue.length - maxQueued);
        }
      }
    } finally {
      _sending = false;
    }
    if (_queue.isNotEmpty) {
      _timer ??= Timer(flushAfter, () => unawaited(flush()));
    }
  }

  static bool _isTransient(Failure failure) => switch (failure) {
    NetworkFailure() => true,
    ServerFailure(:final statusCode) =>
      statusCode == null || statusCode == 429 || statusCode >= 500,
    _ => false,
  };

  void _onSession() {
    if (_session.hasSession) return;
    _timer?.cancel();
    _timer = null;
    _queue.clear();
  }

  @disposeMethod
  void dispose() {
    _session.removeListener(_onSession);
    _timer?.cancel();
    _lifecycle?.dispose();
  }
}
