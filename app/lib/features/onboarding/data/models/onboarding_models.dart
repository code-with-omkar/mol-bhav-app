import '../../domain/entities/onboarding_entities.dart';

/// Hardcoded business type (API has no `/reference/business-types` endpoint).
class BusinessTypeModel {
  const BusinessTypeModel({required this.id, required this.name});

  final String id;
  final String name;

  BusinessType toEntity() => BusinessType(id: id, name: name);
}

/// `GET /market/states` → `{ "id": "uuid", "name": "Maharashtra", "code": "MH" }`.
class RegionModel {
  const RegionModel({required this.code, required this.name, this.id});

  factory RegionModel.fromStateJson(Map<String, dynamic> json) => RegionModel(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
  );

  /// `GET /market/states/{id}/districts` → `{ "id": "uuid", "name": "Nashik" }`.
  /// District has no code — use name as a human-readable code stored in profile.
  factory RegionModel.fromDistrictJson(Map<String, dynamic> json) =>
      RegionModel(
        id: json['id'] as String,
        code: json['name'] as String,
        name: json['name'] as String,
      );

  /// Guid of this region, used for district-lookup by parent state.
  final String? id;
  final String code;
  final String name;

  Region toEntity() => Region(code: code, name: name);
}

/// `GET /profile` → picker keys (state code, district name, business type).
class SavedProfileModel {
  const SavedProfileModel(this.entity);

  factory SavedProfileModel.fromJson(Map<String, dynamic> json) {
    String? str(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return SavedProfileModel(
      SavedProfile(
        displayName: str('displayName'),
        businessTypeId: str('businessTypeCode') ?? str('businessType'),
        stateCode: str('stateCode') ?? str('state'),
        districtCode: str('districtName') ?? str('district'),
        preferredLanguage: str('preferredLanguage'),
        categoryCodes: {
          for (final c in (json['categories'] as List<dynamic>? ?? const []))
            c as String,
        },
      ),
    );
  }

  final SavedProfile entity;

  Map<String, dynamic> toRequestJson() => {
    'displayName': entity.displayName,
    'businessType': entity.businessTypeId,
    'state': entity.stateCode,
    'district': entity.districtCode,
    'preferredLanguage': ?entity.preferredLanguage,
  };
}

/// Body sent to `PUT /profile` (matches `UpdateProfileRequest`).
class BusinessProfileRequest {
  const BusinessProfileRequest(this.profile);

  final BusinessProfile profile;

  Map<String, dynamic> toJson() => {
    'displayName': profile.displayName,
    'businessType': profile.businessTypeId,
    'state': profile.stateCode,
    'district': profile.districtCode,
    'preferredLanguage': profile.preferredLanguage,
    'categories': const <String>[],
  };
}

/// `GET /catalog/categories` → `{ "id": "…", "code": "agriculture", "name": "Agriculture", … }`.
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
      id: json['code'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      highlights: const [],
      isAvailable: true,
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
