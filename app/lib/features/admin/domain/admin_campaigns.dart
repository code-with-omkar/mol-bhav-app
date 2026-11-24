import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';
import 'admin_ads.dart';

/// Where a sponsored card appears (the API's `PromotionPlacement`).
enum AdPlacement {
  homeFeed('HomeFeed'),
  mandiPrices('MandiPrices'),
  marketComparison('MarketComparison');

  const AdPlacement(this.wire);

  final String wire;

  /// A placement this build does not know reads as [homeFeed].
  static AdPlacement fromWire(String value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => homeFeed);
}

/// Limits the API enforces on a campaign; the form checks the same ones.
abstract final class CampaignLimits {
  static const name = 120;
  static const title = 60;
  static const body = 140;
  static const ctaLabel = 24;
  static const url = 500;
  static const maxPriority = 100;
  static const advertiserName = 120;
  static const gstinLength = 15;
}

/// A business that buys sponsored placements.
class AdminAdvertiser extends Equatable {
  const AdminAdvertiser({
    required this.id,
    required this.name,
    this.contactName,
    this.contactPhone,
    this.gstin,
    this.activeCampaigns = 0,
  });

  final String id;
  final String name;
  final String? contactName;
  final String? contactPhone;
  final String? gstin;
  final int activeCampaigns;

  @override
  List<Object?> get props => [
    id,
    name,
    contactName,
    contactPhone,
    gstin,
    activeCampaigns,
  ];
}

/// A category, with an optional state, a campaign is shown to (no state = every
/// state).
class CampaignTarget extends Equatable {
  const CampaignTarget({required this.categoryCode, this.stateId});

  final String categoryCode;
  final String? stateId;

  @override
  List<Object?> get props => [categoryCode, stateId];
}

/// A campaign as the admin list returns it.
class AdminCampaign extends Equatable {
  const AdminCampaign({
    required this.id,
    required this.advertiserId,
    required this.advertiserName,
    required this.name,
    required this.placement,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.priority,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.targets,
    this.dailyCap,
    this.imageUrl,
  });

  final String id;
  final String advertiserId;
  final String advertiserName;
  final String name;
  final AdPlacement placement;
  final CampaignState status;
  final DateTime startsAt;
  final DateTime endsAt;
  final int priority;
  final int? dailyCap;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaUrl;
  final String? imageUrl;
  final List<CampaignTarget> targets;

  /// An ended campaign is final: the API refuses any edit.
  bool get isEnded => status == CampaignState.ended;

  /// The categories it targets, each once.
  Set<String> get categoryCodes => {for (final t in targets) t.categoryCode};

  /// The states it targets (empty = every state).
  Set<String> get stateIds => {
    for (final t in targets)
      if (t.stateId != null) t.stateId!,
  };

  /// Whether the targets are exactly "these categories in these states" (or
  /// every state), which is all the form can express. A campaign set up
  /// through the API with an uneven mix would be flattened by a save.
  bool get targetsFitForm {
    final states = stateIds;
    final expected = <CampaignTarget>{
      for (final c in categoryCodes)
        if (states.isEmpty)
          CampaignTarget(categoryCode: c)
        else
          for (final s in states) CampaignTarget(categoryCode: c, stateId: s),
    };
    return expected.length == targets.toSet().length &&
        expected.containsAll(targets);
  }

  @override
  List<Object?> get props => [
    id,
    advertiserId,
    advertiserName,
    name,
    placement,
    status,
    startsAt,
    endsAt,
    priority,
    dailyCap,
    title,
    body,
    ctaLabel,
    ctaUrl,
    imageUrl,
    targets,
  ];
}

enum CampaignAction { activate, pause, end }

/// The editable part of a campaign, as typed into the form.
class CampaignDraft extends Equatable {
  const CampaignDraft({
    this.advertiserId,
    this.name = '',
    this.placement = AdPlacement.homeFeed,
    this.title = '',
    this.body = '',
    this.ctaLabel = '',
    this.ctaUrl = '',
    this.imageUrl = '',
    this.startsOn,
    this.endsOn,
    this.priority = '0',
    this.dailyCap = '',
    this.categoryCodes = const {},
    this.stateIds = const {},
  });

  /// A draft that starts from an existing campaign.
  factory CampaignDraft.from(AdminCampaign c) => CampaignDraft(
    advertiserId: c.advertiserId,
    name: c.name,
    placement: c.placement,
    title: c.title,
    body: c.body,
    ctaLabel: c.ctaLabel,
    ctaUrl: c.ctaUrl,
    imageUrl: c.imageUrl ?? '',
    startsOn: DateTime(c.startsAt.year, c.startsAt.month, c.startsAt.day),
    endsOn: DateTime(c.endsAt.year, c.endsAt.month, c.endsAt.day),
    priority: '${c.priority}',
    dailyCap: c.dailyCap == null ? '' : '${c.dailyCap}',
    categoryCodes: c.categoryCodes,
    stateIds: c.stateIds,
  );

  final String? advertiserId;
  final String name;
  final AdPlacement placement;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaUrl;
  final String imageUrl;

  /// Calendar days (local); the campaign runs from the start of the first to
  /// the end of the last.
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// Kept as typed so the field can show half-written input.
  final String priority;
  final String dailyCap;
  final Set<String> categoryCodes;
  final Set<String> stateIds;

  CampaignDraft copyWith({
    String? Function()? advertiserId,
    String? name,
    AdPlacement? placement,
    String? title,
    String? body,
    String? ctaLabel,
    String? ctaUrl,
    String? imageUrl,
    DateTime? Function()? startsOn,
    DateTime? Function()? endsOn,
    String? priority,
    String? dailyCap,
    Set<String>? categoryCodes,
    Set<String>? stateIds,
  }) => CampaignDraft(
    advertiserId: advertiserId != null ? advertiserId() : this.advertiserId,
    name: name ?? this.name,
    placement: placement ?? this.placement,
    title: title ?? this.title,
    body: body ?? this.body,
    ctaLabel: ctaLabel ?? this.ctaLabel,
    ctaUrl: ctaUrl ?? this.ctaUrl,
    imageUrl: imageUrl ?? this.imageUrl,
    startsOn: startsOn != null ? startsOn() : this.startsOn,
    endsOn: endsOn != null ? endsOn() : this.endsOn,
    priority: priority ?? this.priority,
    dailyCap: dailyCap ?? this.dailyCap,
    categoryCodes: categoryCodes ?? this.categoryCodes,
    stateIds: stateIds ?? this.stateIds,
  );

  int? get priorityValue => int.tryParse(priority.trim());

  int? get dailyCapValue =>
      dailyCap.trim().isEmpty ? null : int.tryParse(dailyCap.trim());

  /// The start of the first day, as an instant.
  DateTime? get startsAt => startsOn == null
      ? null
      : DateTime(startsOn!.year, startsOn!.month, startsOn!.day).toUtc();

  /// The last second of the last day, as an instant.
  DateTime? get endsAt => endsOn == null
      ? null
      : DateTime(endsOn!.year, endsOn!.month, endsOn!.day, 23, 59, 59).toUtc();

  /// The request body (`CampaignRequest`). Targets are every chosen category,
  /// in every chosen state, or in all states when none are chosen.
  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'placement': placement.wire,
    'title': title.trim(),
    'body': body.trim(),
    'ctaLabel': ctaLabel.trim(),
    'ctaUrl': ctaUrl.trim(),
    'imageUrl': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
    'startsAtUtc': startsAt?.toIso8601String(),
    'endsAtUtc': endsAt?.toIso8601String(),
    'priority': priorityValue ?? 0,
    'dailyImpressionCap': dailyCapValue,
    'targets': [
      for (final c in categoryCodes)
        if (stateIds.isEmpty)
          {'categoryCode': c, 'stateId': null}
        else
          for (final s in stateIds) {'categoryCode': c, 'stateId': s},
    ],
  };

  @override
  List<Object?> get props => [
    advertiserId,
    name,
    placement,
    title,
    body,
    ctaLabel,
    ctaUrl,
    imageUrl,
    startsOn,
    endsOn,
    priority,
    dailyCap,
    categoryCodes,
    stateIds,
  ];
}

/// What is wrong with a [CampaignDraft], field by field; the same rules the
/// API applies, so a save is refused before it is sent.
enum CampaignProblem {
  advertiserMissing,
  nameInvalid,
  titleInvalid,
  bodyInvalid,
  ctaLabelInvalid,
  ctaUrlInvalid,
  imageUrlInvalid,
  startMissing,
  endMissing,
  endBeforeStart,
  priorityInvalid,
  dailyCapInvalid,
  categoriesMissing,
}

/// Every problem with [draft]; empty = it can be saved.
Set<CampaignProblem> campaignProblems(CampaignDraft draft) {
  bool within(String text, int max) {
    final t = text.trim();
    return t.isNotEmpty && t.length <= max;
  }

  bool httpsLink(String text) {
    final t = text.trim();
    final uri = Uri.tryParse(t);
    return t.length <= CampaignLimits.url &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.hasAuthority &&
        uri.host.isNotEmpty;
  }

  final priority = draft.priorityValue;
  final cap = draft.dailyCapValue;
  return {
    if (draft.advertiserId == null) CampaignProblem.advertiserMissing,
    if (!within(draft.name, CampaignLimits.name)) CampaignProblem.nameInvalid,
    if (!within(draft.title, CampaignLimits.title))
      CampaignProblem.titleInvalid,
    if (!within(draft.body, CampaignLimits.body)) CampaignProblem.bodyInvalid,
    if (!within(draft.ctaLabel, CampaignLimits.ctaLabel))
      CampaignProblem.ctaLabelInvalid,
    if (!httpsLink(draft.ctaUrl)) CampaignProblem.ctaUrlInvalid,
    if (draft.imageUrl.trim().isNotEmpty && !httpsLink(draft.imageUrl))
      CampaignProblem.imageUrlInvalid,
    if (draft.startsOn == null) CampaignProblem.startMissing,
    if (draft.endsOn == null) CampaignProblem.endMissing,
    if (draft.startsOn != null &&
        draft.endsOn != null &&
        draft.endsOn!.isBefore(draft.startsOn!))
      CampaignProblem.endBeforeStart,
    if (priority == null ||
        priority < 0 ||
        priority > CampaignLimits.maxPriority)
      CampaignProblem.priorityInvalid,
    if (draft.dailyCap.trim().isNotEmpty && (cap == null || cap < 1))
      CampaignProblem.dailyCapInvalid,
    if (draft.categoryCodes.isEmpty) CampaignProblem.categoriesMissing,
  };
}

/// What the form lets an admin pick from.
class AdminState extends Equatable {
  const AdminState({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

abstract interface class AdminCampaignsRepository {
  /// Campaigns newest first; [status] narrows them, null = all.
  Future<Result<List<AdminCampaign>>> getCampaigns({
    CampaignState? status,
    required int page,
    required int pageSize,
  });

  Future<Result<List<AdminAdvertiser>>> getAdvertisers();

  /// Returns the new advertiser's id.
  Future<Result<String>> createAdvertiser({
    required String name,
    String? contactName,
    String? contactPhone,
    String? gstin,
  });

  /// Creates the campaign as a draft; returns its id.
  Future<Result<String>> createCampaign(CampaignDraft draft);

  Future<Result<void>> updateCampaign(String id, CampaignDraft draft);

  Future<Result<void>> setStatus(String id, CampaignAction action);

  /// The states a campaign can be limited to.
  Future<Result<List<AdminState>>> getStates();
}
