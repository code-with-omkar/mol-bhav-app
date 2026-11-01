import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_ads.dart';

class AdminCampaignState extends Equatable {
  const AdminCampaignState({this.days = 30, this.data = const DataState()});

  final int days;

  /// Days with no delivery are included (as zeros) so the charts keep a steady
  /// time axis.
  final DataState<List<AdsDay>> data;

  @override
  List<Object?> get props => [days, data];
}

/// One campaign's delivery per day, for the admin Ads tab's detail page.
@injectable
class AdminCampaignCubit extends Cubit<AdminCampaignState> {
  AdminCampaignCubit(this._repository) : super(const AdminCampaignState());

  final AdminAdsRepository _repository;
  String _campaignId = '';

  Future<void> load(String campaignId, {int? days}) async {
    _campaignId = campaignId;
    final range = days ?? state.days;
    emit(
      AdminCampaignState(
        days: range,
        data: DataState.loading(data: state.data.data),
      ),
    );
    final result = await _repository.getCampaignDaily(
      campaignId: campaignId,
      days: range,
    );
    // A range picked meanwhile has its own load in flight; this one is stale.
    if (isClosed || state.days != range) return;
    emit(
      AdminCampaignState(
        days: range,
        data: result.fold(
          (failure) => DataState(
            status: LoadStatus.failure,
            data: state.data.data,
            failure: failure,
          ),
          (rows) => DataState.ready(_filled(rows, range)),
        ),
      ),
    );
  }

  Future<void> setDays(int days) {
    if (days == state.days) return Future.value();
    emit(AdminCampaignState(days: days, data: state.data));
    return load(_campaignId, days: days);
  }

  Future<void> reload() => load(_campaignId);

  /// One entry per day of the last [days] days, zeros where the API sent none.
  static List<AdsDay> _filled(List<AdsDay> rows, int days) {
    DateTime key(DateTime d) => DateTime(d.year, d.month, d.day);
    final byDay = {for (final r in rows) key(r.day): r};
    final today = key(DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        byDay[DateTime(today.year, today.month, today.day - i)] ??
            AdsDay(
              day: DateTime(today.year, today.month, today.day - i),
              impressions: 0,
              clicks: 0,
            ),
    ];
  }
}
