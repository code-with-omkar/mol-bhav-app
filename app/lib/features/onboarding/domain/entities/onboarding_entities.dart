import 'package:equatable/equatable.dart';

/// A buyer segment, e.g. cloud kitchen or civil contractor. Names come from
/// the API, localised to the request language.
class BusinessType extends Equatable {
  const BusinessType({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// An Indian state or a district within one.
class Region extends Equatable {
  const Region({required this.code, required this.name});

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// Reference data for the business-profile form.
class ProfileOptions extends Equatable {
  const ProfileOptions({required this.businessTypes, required this.states});

  final List<BusinessType> businessTypes;
  final List<Region> states;

  @override
  List<Object?> get props => [businessTypes, states];
}

class BusinessProfile extends Equatable {
  const BusinessProfile({
    required this.businessTypeId,
    required this.stateCode,
    required this.districtCode,
    required this.preferredLanguage,
  });

  final String businessTypeId;
  final String stateCode;
  final String districtCode;

  /// Language code for alerts, WhatsApp messages and reports.
  final String preferredLanguage;

  @override
  List<Object?> get props => [
    businessTypeId,
    stateCode,
    districtCode,
    preferredLanguage,
  ];
}

/// A procurement category such as Agriculture or Construction.
class ProcurementCategory extends Equatable {
  const ProcurementCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.highlights,
    required this.isAvailable,
  });

  final String id;

  /// Stable key (`agriculture`, `construction`, …) used for icon and tone.
  final String code;
  final String name;

  /// Short descriptors shown under the name, e.g. Commodities, Mandis.
  final List<String> highlights;

  /// `false` for categories that have not launched yet ("Coming soon").
  final bool isAvailable;

  @override
  List<Object?> get props => [id, code, name, highlights, isAvailable];
}
