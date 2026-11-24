import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_ads.dart';
import '../domain/admin_campaigns.dart';

/// `/admin/promotions/campaigns` and `/advertisers`, plus `/market/states` for
/// the targeting list.
@LazySingleton(as: AdminCampaignsRepository)
class AdminCampaignsRepositoryImpl implements AdminCampaignsRepository {
  AdminCampaignsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminCampaign>>> getCampaigns({
    CampaignState? status,
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>(
      '/admin/promotions/campaigns',
      queryParameters: {
        'status': ?status == null ? null : _statusWire(status),
        'page': page,
        'pageSize': pageSize,
      },
    )).data;
    return [
      for (final row in (rows ?? const []).cast<Map<String, dynamic>>())
        parseCampaign(row),
    ];
  });

  @override
  Future<Result<List<AdminAdvertiser>>> getAdvertisers() =>
      runApiCall(() async {
        final rows = (await _dio.get<List<dynamic>>(
          '/admin/promotions/advertisers',
        )).data;
        return [
          for (final j in (rows ?? const []).cast<Map<String, dynamic>>())
            AdminAdvertiser(
              id: j.str('id'),
              name: j.str('name'),
              contactName: j.strOrNull('contactName'),
              contactPhone: j.strOrNull('contactPhone'),
              gstin: j.strOrNull('gstin'),
              activeCampaigns: j.integer('activeCampaigns'),
            ),
        ];
      });

  @override
  Future<Result<String>> createAdvertiser({
    required String name,
    String? contactName,
    String? contactPhone,
    String? gstin,
  }) => runApiCall(() async {
    String? blankToNull(String? v) =>
        v == null || v.trim().isEmpty ? null : v.trim();
    final body = (await _dio.post<Map<String, dynamic>>(
      '/admin/promotions/advertisers',
      data: {
        'name': name.trim(),
        'contactName': blankToNull(contactName),
        'contactPhone': blankToNull(contactPhone),
        'gstin': blankToNull(gstin),
      },
    )).data!;
    return body.str('id');
  });

  @override
  Future<Result<String>> createCampaign(CampaignDraft draft) => runApiCall(
    () async {
      final body = (await _dio.post<Map<String, dynamic>>(
        '/admin/promotions/campaigns',
        data: {'advertiserId': draft.advertiserId, 'campaign': draft.toJson()},
      )).data!;
      return body.str('id');
    },
  );

  @override
  Future<Result<void>> updateCampaign(String id, CampaignDraft draft) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/promotions/campaigns/${Uri.encodeComponent(id)}',
          data: draft.toJson(),
        ),
      );

  @override
  Future<Result<void>> setStatus(String id, CampaignAction action) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/promotions/campaigns/${Uri.encodeComponent(id)}/status',
          data: {
            'action': switch (action) {
              CampaignAction.activate => 'Activate',
              CampaignAction.pause => 'Pause',
              CampaignAction.end => 'End',
            },
          },
        ),
      );

  @override
  Future<Result<List<AdminState>>> getStates() => runApiCall(() async {
    final rows = (await _dio.get<List<dynamic>>('/market/states')).data;
    return [
      for (final j in (rows ?? const []).cast<Map<String, dynamic>>())
        AdminState(id: j.str('id'), name: j.str('name')),
    ];
  });

  static AdminCampaign parseCampaign(Map<String, dynamic> j) => AdminCampaign(
    id: j.str('id'),
    advertiserId: j.str('advertiserId'),
    advertiserName: j.str('advertiserName'),
    name: j.str('name'),
    placement: AdPlacement.fromWire(j.str('placement')),
    status: CampaignState.fromWire(j.str('status')),
    startsAt: j.date('startsAtUtc'),
    endsAt: j.date('endsAtUtc'),
    priority: j.integer('priority'),
    dailyCap: j['dailyImpressionCap'] is int
        ? j['dailyImpressionCap'] as int
        : null,
    title: j.str('title'),
    body: j.str('body'),
    ctaLabel: j.str('ctaLabel'),
    ctaUrl: j.str('ctaUrl'),
    imageUrl: j.strOrNull('imageUrl'),
    targets: j.list(
      'targets',
      (t) => CampaignTarget(
        categoryCode: t.str('categoryCode'),
        stateId: t.strOrNull('stateId'),
      ),
    ),
  );

  static String _statusWire(CampaignState s) => switch (s) {
    CampaignState.draft => 'Draft',
    CampaignState.active => 'Active',
    CampaignState.paused => 'Paused',
    CampaignState.ended => 'Ended',
  };
}
