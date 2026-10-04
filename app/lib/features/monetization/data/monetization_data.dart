import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/monetization.dart';

/// Free-tier limits and rewarded-ad unlocks:
///
/// - `GET /monetization/entitlements`
/// - `POST /monetization/unlock-sessions` `{ feature }` → session
/// - `GET /monetization/unlock-sessions/{id}` → session
/// - `POST /monetization/unlock-sessions/{id}/no-fill` → session
///
/// Never cached: every answer depends on what the user did seconds ago.
@LazySingleton(as: MonetizationRepository)
class MonetizationRepositoryImpl implements MonetizationRepository {
  MonetizationRepositoryImpl(this._dio);

  final Dio _dio;

  static const _base = '/monetization';

  @override
  Future<Result<Entitlements>> getEntitlements() => runApiCall(
    () async => _entitlements(
      (await _dio.get<Map<String, dynamic>>('$_base/entitlements')).data!,
    ),
  );

  @override
  Future<Result<AdUnlockSession>> startUnlock(LimitedFeature feature) =>
      runApiCall(
        () async => _session(
          (await _dio.post<Map<String, dynamic>>(
            '$_base/unlock-sessions',
            data: {'feature': _featureName(feature)},
          )).data!,
        ),
      );

  @override
  Future<Result<AdUnlockSession>> getSession(String id) => runApiCall(
    () async => _session(
      (await _dio.get<Map<String, dynamic>>(
        '$_base/unlock-sessions/${Uri.encodeComponent(id)}',
      )).data!,
    ),
  );

  @override
  Future<Result<AdUnlockSession>> completeWithoutAds(String id) => runApiCall(
    () async => _session(
      (await _dio.post<Map<String, dynamic>>(
        '$_base/unlock-sessions/${Uri.encodeComponent(id)}/no-fill',
      )).data!,
    ),
  );

  static String _featureName(LimitedFeature feature) => switch (feature) {
    LimitedFeature.watchlist => 'WatchlistSlots',
    LimitedFeature.alertRules => 'AlertRuleSlots',
    LimitedFeature.proReport => 'PriceHistoryReport',
  };

  static LimitedFeature _feature(String name) => switch (name) {
    'WatchlistSlots' => LimitedFeature.watchlist,
    'AlertRuleSlots' => LimitedFeature.alertRules,
    _ => LimitedFeature.proReport,
  };

  static Entitlements _entitlements(Map<String, dynamic> j) {
    final reports = j.obj('priceHistoryReports');
    return Entitlements(
      isPro: j.flag('isPro'),
      watchlist: _slots(j.obj('watchlist')),
      alertRules: _slots(j.obj('alertRules')),
      reports: ReportEntitlement(
        availableUnlocks: reports.integer('availableUnlocks'),
        unlocksLeftToday: reports.integer('unlocksLeftToday'),
        adsPerUnlock: reports.integer('adsPerUnlock'),
        canUnlockWithAds: reports.flag('canUnlockWithAds'),
      ),
    );
  }

  static SlotEntitlement _slots(Map<String, dynamic> j) => SlotEntitlement(
    used: j.integer('used'),
    limit: j.numberOrNull('limit')?.toInt(),
    maximum: j.numberOrNull('maximum')?.toInt(),
    slotsPerUnlock: j.integer('slotsPerUnlock'),
    adsPerUnlock: j.integer('adsPerUnlock'),
    canUnlockWithAds: j.flag('canUnlockWithAds'),
  );

  static AdUnlockSession _session(Map<String, dynamic> j) => AdUnlockSession(
    id: j.str('id'),
    feature: _feature(j.str('feature')),
    adsRequired: j.integer('adsRequired'),
    adsVerified: j.integer('adsVerified'),
    status: j.str('status') == 'Granted'
        ? AdUnlockStatus.granted
        : AdUnlockStatus.pending,
    expiresAt: j.date('expiresAtUtc'),
  );
}
