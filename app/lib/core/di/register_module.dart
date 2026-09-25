import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/locale_repository.dart';
import '../network/api_config.dart';
import '../network/interceptors.dart';
import '../session/session_manager.dart';
import '../session/token_refresher.dart';
import '../storage/token_storage.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Dio dio(
    TokenStorage tokens,
    TokenRefresher refresher,
    SessionManager session,
    LocaleRepository locale,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    return dio
      ..interceptors.addAll([
        LanguageInterceptor(locale),
        AuthInterceptor(tokens, refresher, session, dio),
      ]);
  }
}
