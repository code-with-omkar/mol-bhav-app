import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';

/// A capacity limit (watchlist items, alert rules). [limit] and [maximum] are
/// `null` for Pro — unlimited.
class SlotEntitlement extends Equatable {
  const SlotEntitlement({
    required this.used,
    required this.limit,
    required this.maximum,
    required this.slotsPerUnlock,
    required this.adsPerUnlock,
    required this.canUnlockWithAds,
  });

  final int used;
  final int? limit;
  final int? maximum;
  final int slotsPerUnlock;
  final int adsPerUnlock;
  final bool canUnlockWithAds;

  @override
  List<Object?> get props => [
    used,
    limit,
    maximum,
    slotsPerUnlock,
    adsPerUnlock,
    canUnlockWithAds,
  ];
}

/// Pro-only reports a free user may unlock with ads, a few times a day.
class ReportEntitlement extends Equatable {
  const ReportEntitlement({
    required this.availableUnlocks,
    required this.unlocksLeftToday,
    required this.adsPerUnlock,
    required this.canUnlockWithAds,
  });

  final int availableUnlocks;
  final int unlocksLeftToday;
  final int adsPerUnlock;
  final bool canUnlockWithAds;

  @override
  List<Object?> get props => [
    availableUnlocks,
    unlocksLeftToday,
    adsPerUnlock,
    canUnlockWithAds,
  ];
}

class Entitlements extends Equatable {
  const Entitlements({
    required this.isPro,
    required this.watchlist,
    required this.alertRules,
    required this.reports,
  });

  final bool isPro;
  final SlotEntitlement watchlist;
  final SlotEntitlement alertRules;
  final ReportEntitlement reports;

  int adsPerUnlock(LimitedFeature feature) => switch (feature) {
    LimitedFeature.watchlist => watchlist.adsPerUnlock,
    LimitedFeature.alertRules => alertRules.adsPerUnlock,
    LimitedFeature.proReport => reports.adsPerUnlock,
  };

  bool canUnlockWithAds(LimitedFeature feature) => switch (feature) {
    LimitedFeature.watchlist => watchlist.canUnlockWithAds,
    LimitedFeature.alertRules => alertRules.canUnlockWithAds,
    LimitedFeature.proReport => reports.canUnlockWithAds,
  };

  /// Slots one unlock adds; `1` for a report.
  int slotsPerUnlock(LimitedFeature feature) => switch (feature) {
    LimitedFeature.watchlist => watchlist.slotsPerUnlock,
    LimitedFeature.alertRules => alertRules.slotsPerUnlock,
    LimitedFeature.proReport => 1,
  };

  @override
  List<Object?> get props => [isPro, watchlist, alertRules, reports];
}

enum AdUnlockStatus { pending, granted }

/// A "watch N ads" offer in progress. Only the server moves it to
/// [AdUnlockStatus.granted], once AdMob's signed callbacks arrive.
class AdUnlockSession extends Equatable {
  const AdUnlockSession({
    required this.id,
    required this.feature,
    required this.adsRequired,
    required this.adsVerified,
    required this.status,
    required this.expiresAt,
  });

  final String id;
  final LimitedFeature feature;
  final int adsRequired;
  final int adsVerified;
  final AdUnlockStatus status;
  final DateTime expiresAt;

  bool get isGranted => status == AdUnlockStatus.granted;

  bool isOpenAt(DateTime now) =>
      status == AdUnlockStatus.pending && now.isBefore(expiresAt);

  @override
  List<Object?> get props => [
    id,
    feature,
    adsRequired,
    adsVerified,
    status,
    expiresAt,
  ];
}

abstract interface class MonetizationRepository {
  Future<Result<Entitlements>> getEntitlements();

  Future<Result<AdUnlockSession>> startUnlock(LimitedFeature feature);

  Future<Result<AdUnlockSession>> getSession(String id);

  /// No ad could be loaded: the server grants anyway, once a day.
  Future<Result<AdUnlockSession>> completeWithoutAds(String id);
}

@injectable
class GetEntitlements {
  const GetEntitlements(this._repository);

  final MonetizationRepository _repository;

  Future<Result<Entitlements>> call() => _repository.getEntitlements();
}

@injectable
class StartAdUnlock {
  const StartAdUnlock(this._repository);

  final MonetizationRepository _repository;

  Future<Result<AdUnlockSession>> call(LimitedFeature feature) =>
      _repository.startUnlock(feature);
}

@injectable
class GetAdUnlockSession {
  const GetAdUnlockSession(this._repository);

  final MonetizationRepository _repository;

  Future<Result<AdUnlockSession>> call(String id) => _repository.getSession(id);
}

@injectable
class CompleteUnlockWithoutAds {
  const CompleteUnlockWithoutAds(this._repository);

  final MonetizationRepository _repository;

  Future<Result<AdUnlockSession>> call(String id) =>
      _repository.completeWithoutAds(id);
}
