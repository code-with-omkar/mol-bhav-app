import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../models/onboarding_models.dart';

/// Onboarding endpoints. Names in responses are localised by the API from the
/// `Accept-Language` header. Throws [DioException] on failure.
abstract interface class OnboardingRemoteDataSource {
  /// `GET /reference/business-types` → `[BusinessTypeModel]`.
  Future<List<BusinessTypeModel>> getBusinessTypes();

  /// `GET /reference/states` → `[RegionModel]`.
  Future<List<RegionModel>> getStates();

  /// `GET /reference/states/{stateCode}/districts` → `[RegionModel]`.
  Future<List<RegionModel>> getDistricts(String stateCode);

  /// `PUT /me/business-profile` with [BusinessProfileRequest].
  Future<void> saveBusinessProfile(BusinessProfileRequest request);

  /// `GET /categories` → `[CategoryModel]`.
  Future<List<CategoryModel>> getCategories();

  /// `PUT /me/categories` with `{ "categoryIds": ["1", "2"] }`.
  Future<void> saveCategories(List<String> categoryIds);
}

@LazySingleton(as: OnboardingRemoteDataSource)
class DioOnboardingRemoteDataSource implements OnboardingRemoteDataSource {
  DioOnboardingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _dio.get<List<dynamic>>(path);
    return [
      for (final item in response.data!) fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<BusinessTypeModel>> getBusinessTypes() =>
      _getList('/reference/business-types', BusinessTypeModel.fromJson);

  @override
  Future<List<RegionModel>> getStates() =>
      _getList('/reference/states', RegionModel.fromJson);

  @override
  Future<List<RegionModel>> getDistricts(String stateCode) => _getList(
    '/reference/states/${Uri.encodeComponent(stateCode)}/districts',
    RegionModel.fromJson,
  );

  @override
  Future<void> saveBusinessProfile(BusinessProfileRequest request) =>
      _dio.put<void>('/me/business-profile', data: request.toJson());

  @override
  Future<List<CategoryModel>> getCategories() =>
      _getList('/categories', CategoryModel.fromJson);

  @override
  Future<void> saveCategories(List<String> categoryIds) =>
      _dio.put<void>('/me/categories', data: {'categoryIds': categoryIds});
}
