import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// Whether the automatically refreshed price feeds are keeping up
/// (`GET /pricing/data-status`).
class PriceDataStatus extends Equatable {
  const PriceDataStatus({required this.isDelayed, this.lastUpdatedAt});

  /// A feed has not brought data in for too long, or its latest run failed.
  final bool isDelayed;

  /// When a feed last brought data in; `null` if none ever has.
  final DateTime? lastUpdatedAt;

  @override
  List<Object?> get props => [isDelayed, lastUpdatedAt];
}

abstract interface class PriceDataStatusRepository {
  Future<Result<PriceDataStatus>> getStatus();
}
