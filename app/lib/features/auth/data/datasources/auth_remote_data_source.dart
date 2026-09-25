import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/interceptors.dart';
import '../models/auth_models.dart';

/// Mobile-OTP sign-in endpoints. Throws [DioException] on failure.
abstract interface class AuthRemoteDataSource {
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
