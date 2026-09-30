import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/cache/cached_api_call.dart';
import '../../../../core/cache/response_cache.dart';
import '../../../../core/locale/locale_repository.dart';
import '../models/onboarding_models.dart';

const _kPendingProfile = 'onboarding.pendingProfile';

/// Hardcoded business types (the API has no reference endpoint for these).
const _kBusinessTypes = [
  BusinessTypeModel(id: 'Trader', name: 'Trader'),
  BusinessTypeModel(id: 'Retailer', name: 'Retailer'),
  BusinessTypeModel(id: 'Wholesaler', name: 'Wholesaler'),
  BusinessTypeModel(id: 'Farmer', name: 'Farmer'),
  BusinessTypeModel(id: 'Processor', name: 'Processor'),
  BusinessTypeModel(id: 'Civil Contractor', name: 'Civil Contractor'),
  BusinessTypeModel(id: 'Builder', name: 'Builder'),
  BusinessTypeModel(id: 'Other', name: 'Other'),
];

/// Onboarding endpoints.
abstract interface class OnboardingRemoteDataSource {
  /// Returns hardcoded business type list (no API endpoint).
  Future<List<BusinessTypeModel>> getBusinessTypes();

  /// `GET /market/states` → `[RegionModel]`.
  Future<List<RegionModel>> getStates();

  /// `GET /market/states/{stateId:guid}/districts` → `[RegionModel]`.
  Future<List<RegionModel>> getDistricts(String stateCode);

  /// Stores profile in SharedPreferences; committed together with categories
  /// in [saveCategories] via `PUT /profile`.
  Future<void> saveBusinessProfile(BusinessProfileRequest request);

  /// `GET /catalog/categories` → `[CategoryModel]`.
  Future<List<CategoryModel>> getCategories();

  /// Reads the pending business profile from SharedPreferences (or the saved
  /// profile when editing categories alone), merges [categoryIds], then calls
  /// `PUT /profile`.
  Future<void> saveCategories(List<String> categoryIds);

  /// `GET /profile`.
  Future<Map<String, dynamic>> getSavedProfile();
}

@LazySingleton(as: OnboardingRemoteDataSource)
class DioOnboardingRemoteDataSource implements OnboardingRemoteDataSource {
  DioOnboardingRemoteDataSource(
    this._dio,
    this._prefs,
    this._locale,
    this._cache,
  );

  final Dio _dio;
  final SharedPreferences _prefs;
  final LocaleRepository _locale;
  final ResponseCache _cache;

  /// state.code → state.id (Guid string), populated on first getStates() call.
  final Map<String, String> _stateIds = {};

  /// Reference lists: a cached body younger than [referenceDataTtl] is used
  /// as is. Keys match the other screens that read the same endpoints.
  Future<List<T>> _getList<T>(
    String cacheKey,
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cached = _cache.read(cacheKey);
    final List<dynamic> data;
    if (cached != null &&
        cached.data is List<dynamic> &&
        DateTime.now().difference(cached.savedAt) < referenceDataTtl) {
      data = cached.data as List<dynamic>;
    } else {
      data = (await _dio.get<List<dynamic>>(path)).data!;
      await _cache.write(cacheKey, data);
    }
    return [for (final item in data) fromJson(item as Map<String, dynamic>)];
  }

  @override
  Future<List<BusinessTypeModel>> getBusinessTypes() async => _kBusinessTypes;

  @override
  Future<List<RegionModel>> getStates() async {
    final states = await _getList(
      'market.states',
      '/market/states',
      RegionModel.fromStateJson,
    );
    for (final s in states) {
      if (s.id != null) _stateIds[s.code] = s.id!;
    }
    return states;
  }

  @override
  Future<List<RegionModel>> getDistricts(String stateCode) async {
    final stateId = _stateIds[stateCode];
    if (stateId == null) {
      throw StateError(
        'State id for "$stateCode" not cached — call getStates() first.',
      );
    }
    return _getList(
      'market.districts.$stateId',
      '/market/states/${Uri.encodeComponent(stateId)}/districts',
      RegionModel.fromDistrictJson,
    );
  }

  @override
  Future<void> saveBusinessProfile(BusinessProfileRequest request) async {
    await _prefs.setString(_kPendingProfile, jsonEncode(request.toJson()));
  }

  @override
  Future<List<CategoryModel>> getCategories() => _getList(
    'catalog.categories',
    '/catalog/categories',
    CategoryModel.fromJson,
  );

  @override
  Future<void> saveCategories(List<String> categoryIds) async {
    final raw = _prefs.getString(_kPendingProfile);
    // PUT /profile is a full replacement: without a pending profile, keep
    // the saved business fields.
    final body = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : SavedProfileModel.fromJson(await getSavedProfile()).toRequestJson();
    body['categories'] = categoryIds;
    body.putIfAbsent('preferredLanguage', () => _locale.current.code);
    await _dio.put<void>('/profile', data: body);
    await _prefs.remove(_kPendingProfile);
  }

  @override
  Future<Map<String, dynamic>> getSavedProfile() async =>
      (await _dio.get<Map<String, dynamic>>('/profile')).data!;
}
