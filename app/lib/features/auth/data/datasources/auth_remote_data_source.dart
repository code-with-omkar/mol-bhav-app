import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/interceptors.dart';
import '../models/auth_models.dart';

/// Sign-in endpoints (password and mobile OTP). Throws [DioException] on failure.
abstract interface class AuthRemoteDataSource {
  /// `GET /auth/methods` → `{ "otp": false, "password": true }`.
  Future<LoginMethodsResponse> getLoginMethods();

  /// `POST /auth/password/login` with `{ "phoneNumber": "…", "password": "…" }`.
  /// Responds 400 for a wrong number or password, 422 when locked out.
  Future<OtpVerifyResponse> loginWithPassword(
    String phoneNumber,
    String password,
  );

  /// `POST /auth/password/register` with `{ "phoneNumber": "…", "password": "…" }`.
  /// Responds 409 when the number already has an account.
  Future<OtpVerifyResponse> registerWithPassword(
    String phoneNumber,
    String password,
  );

  /// `POST /auth/otp/request` with `{ "phoneNumber": "+919876543210" }`.
  Future<OtpRequestResponse> requestOtp(String phoneNumber);

  /// `POST /auth/otp/verify` with `{ "phoneNumber": "…", "code": "123456" }`.
  /// Responds 400 or 422 when the code is wrong or expired.
  Future<OtpVerifyResponse> verifyOtp(String phoneNumber, String code);
}

@LazySingleton(as: AuthRemoteDataSource)
class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  DioAuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// OTP calls happen before a session exists; a 401 means a wrong code.
  static final _noSession = Options(extra: {AuthInterceptor.skipAuth: true});

  @override
  Future<LoginMethodsResponse> getLoginMethods() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/methods',
      options: _noSession,
    );
    return LoginMethodsResponse.fromJson(response.data!);
  }

  @override
  Future<OtpVerifyResponse> loginWithPassword(
    String phoneNumber,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/password/login',
      data: {'phoneNumber': phoneNumber, 'password': password},
      options: _noSession,
    );
    return OtpVerifyResponse.fromJson(response.data!);
  }

  @override
  Future<OtpVerifyResponse> registerWithPassword(
    String phoneNumber,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/password/register',
      data: {'phoneNumber': phoneNumber, 'password': password},
      options: _noSession,
    );
    return OtpVerifyResponse.fromJson(response.data!);
  }

  @override
  Future<OtpRequestResponse> requestOtp(String phoneNumber) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/request',
      data: {'phoneNumber': phoneNumber},
      options: _noSession,
    );
    return OtpRequestResponse.fromJson(response.data!);
  }

  @override
  Future<OtpVerifyResponse> verifyOtp(String phoneNumber, String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      data: {'phoneNumber': phoneNumber, 'code': code},
      options: _noSession,
    );
    return OtpVerifyResponse.fromJson(response.data!);
  }
}
