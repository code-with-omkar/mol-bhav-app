import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../../../core/session/session_manager.dart';
import '../domain/account.dart';

/// Account endpoints:
///
/// - `GET /profile` → `UserProfileResponse`
/// - `PUT /profile` → full replacement (notifications are part of the same endpoint)
abstract interface class AccountRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();

  Future<void> updateNotifications(Map<String, dynamic> body);
}

@LazySingleton(as: AccountRemoteDataSource)
class DioAccountRemoteDataSource implements AccountRemoteDataSource {
  DioAccountRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getProfile() async =>
      (await _dio.get<Map<String, dynamic>>('/profile')).data!;

  @override
  Future<void> updateNotifications(Map<String, dynamic> body) async {
    // Notification preferences are not yet a separate API endpoint.
    // No-op until a dedicated endpoint is added.
  }
}

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote, this._session, this._cache);

  /// Cache key of `GET /profile`; Home builds on the same profile.
  static const profileKey = 'profile';
  static const homeKey = 'home';

  final AccountRemoteDataSource _remote;
  final SessionManager _session;
  final ResponseCache _cache;

  @override
  Stream<Result<AccountProfile>> watchProfile() => watchCachedApiCall(
    cache: _cache,
    key: profileKey,
    fetch: _remote.getProfile,
    parse: (json) => _profile(json as Map<String, dynamic>),
  );

  @override
  Future<void> invalidateProfile() =>
      _cache.invalidate(const [profileKey, homeKey]);

  static AccountProfile _profile(Map<String, dynamic> j) {
    return AccountProfile(
      name: j.strOrNull('displayName') ?? '',
      phoneNumberMasked: j.strOrNull('phoneNumberMasked') ?? '',
      userId: j.strOrNull('userId') ?? '',
      businessTypeName: j.strOrNull('businessType') ?? '',
      districtName:
          j.strOrNull('districtName') ?? j.strOrNull('district') ?? '',
      stateName: j.strOrNull('stateName') ?? j.strOrNull('state') ?? '',
      stateId: j.strOrNull('stateId'),
      districtId: j.strOrNull('districtId'),
      preferredLanguage: j.strOrNull('preferredLanguage'),
      categoryCodes: j.strings('categories'),
      categoryNames: [
        for (final c in (j['categoryDetails'] as List<dynamic>? ?? const []))
          (c as Map<String, dynamic>).str('name'),
      ],
      isPro: j.str('subscriptionTier') == 'pro',
      pushEnabled: j.flag('pushEnabled'),
      whatsappEnabled: j.flag('whatsAppEnabled'),
    );
  }

  @override
  Future<Result<void>> updateNotifications({
    required bool push,
    required bool whatsapp,
  }) => runApiCall(
    () => _remote.updateNotifications({'push': push, 'whatsapp': whatsapp}),
  );

  @override
  Future<void> signOut() => _session.signOut();
}
