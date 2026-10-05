import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/cache/cached_api_call.dart';
import '../../../core/cache/response_cache.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/notification_prefs.dart';

abstract interface class NotificationDeviceDataSource {
  Future<void> registerToken(String token, String platform);

  Future<void> unregisterToken(String token);
}

abstract interface class NotificationPrefsRemoteDataSource {
  Future<Map<String, dynamic>> getPreferences();

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body);
}

@LazySingleton(as: NotificationDeviceDataSource)
class DioNotificationDeviceDataSource implements NotificationDeviceDataSource {
  DioNotificationDeviceDataSource(this._dio);

  final Dio _dio;

  @override
  Future<void> registerToken(String token, String platform) =>
      _dio.post<void>('/devices', data: {'token': token, 'platform': platform});

  @override
  Future<void> unregisterToken(String token) =>
      _dio.delete<void>('/devices/${Uri.encodeComponent(token)}');
}

@LazySingleton(as: NotificationPrefsRemoteDataSource)
class DioNotificationPrefsRemoteDataSource
    implements NotificationPrefsRemoteDataSource {
  DioNotificationPrefsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getPreferences() async =>
      (await _dio.get<Map<String, dynamic>>('/notification-preferences')).data!;

  @override
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> body,
  ) async => (await _dio.put<Map<String, dynamic>>(
    '/notification-preferences',
    data: body,
  )).data!;
}

@LazySingleton(as: NotificationPrefsRepository)
class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  NotificationPrefsRepositoryImpl(this._remote, this._cache);

  final NotificationPrefsRemoteDataSource _remote;
  final ResponseCache _cache;

  static const prefsKey = 'notifications.prefs';

  /// Only this user changes these, and every save rewrites the saved copy, so
  /// a day-old copy is still right; offline the saved copy beats defaults.
  @override
  Future<NotificationPrefs> getPreferences() => runCachedApiCall(
    cache: _cache,
    key: prefsKey,
    ttl: const Duration(days: 1),
    fetch: () async =>
        (await _remote.getPreferences())['data'] as Map<String, dynamic>,
    parse: (json) => _prefs(json as Map<String, dynamic>),
  ).then((r) => r.fold((_) => const NotificationPrefs.defaults(), (v) => v));

  @override
  Future<NotificationPrefs> updatePreferences(NotificationPrefs prefs) =>
      runApiCall(() async {
        final json =
            (await _remote.updatePreferences({
                  'pushEnabled': prefs.pushEnabled,
                  'alertPushEnabled': prefs.alertPushEnabled,
                  'priceUpdatePushEnabled': prefs.priceUpdatePushEnabled,
                  'whatsAppEnabled': prefs.whatsAppEnabled,
                  'alertWhatsAppEnabled': prefs.alertWhatsAppEnabled,
                }))['data']
                as Map<String, dynamic>;
        await _cache.write(prefsKey, json); // the saved copy is the new truth
        return _prefs(json);
      }).then((r) => r.fold((_) => prefs, (v) => v));

  static NotificationPrefs _prefs(Map<String, dynamic> j) => NotificationPrefs(
    pushEnabled: j.flag('pushEnabled'),
    alertPushEnabled: j.flag('alertPushEnabled'),
    priceUpdatePushEnabled: j.flag('priceUpdatePushEnabled'),
    whatsAppEnabled: j.flag('whatsAppEnabled'),
    alertWhatsAppEnabled: j.flag('alertWhatsAppEnabled'),
  );
}

/// Returns the platform string expected by the API's [DevicePlatform] enum.
String currentDevicePlatform() {
  if (kIsWeb) return 'Web';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'Ios';
  return 'Android';
}
