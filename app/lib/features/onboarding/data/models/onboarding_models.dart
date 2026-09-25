import '../../domain/entities/onboarding_entities.dart';

/// `{ "id": "cloud-kitchen", "name": "Cloud Kitchen" }`
class BusinessTypeModel {
  const BusinessTypeModel({required this.id, required this.name});

  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) =>
      BusinessTypeModel(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  BusinessType toEntity() => BusinessType(id: id, name: name);
}

/// `{ "code": "MH", "name": "Maharashtra" }` (states and districts alike).
class RegionModel {
  const RegionModel({required this.code, required this.name});

  factory RegionModel.fromJson(Map<String, dynamic> json) =>
      RegionModel(code: json['code'] as String, name: json['name'] as String);

  final String code;
  final String name;

  Region toEntity() => Region(code: code, name: name);
}

/// Body of `PUT /me/business-profile`.
class BusinessProfileRequest {
  const BusinessProfileRequest(this.profile);

  final BusinessProfile profile;

  Map<String, dynamic> toJson() => {
    'businessTypeId': profile.businessTypeId,
    'stateCode': profile.stateCode,
    'districtCode': profile.districtCode,
    'preferredLanguage': profile.preferredLanguage,
  };
}

/// ```json
/// { "id": "1", "code": "agriculture", "name": "Agriculture",
///   "highlights": ["Commodities", "Mandis", "Market Prices"],
///   "isAvailable": true }
/// ```
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.highlights,
    required this.isAvailable,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      highlights: [
        for (final item in (json['highlights'] as List<dynamic>? ?? const []))
          item as String,
      ],
      isAvailable: json['isAvailable'] as bool,
    );
  }

  final String id;
  final String code;
  final String name;
  final List<String> highlights;
  final bool isAvailable;

  ProcurementCategory toEntity() => ProcurementCategory(
    id: id,
    code: code,
    name: name,
    highlights: highlights,
    isAvailable: isAvailable,
  );
}
