import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../domain/password_reset.dart';

/// `POST /auth/password/forgot` and `POST /auth/password/reset` (both without
/// a session).
@LazySingleton(as: PasswordResetRepository)
class PasswordResetRepositoryImpl implements PasswordResetRepository {
  PasswordResetRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void>> requestCode(String phoneNumber) => runApiCall(() async {
    await _dio.post<void>(
      '/auth/password/forgot',
      data: {'phoneNumber': phoneNumber},
    );
  });

  @override
  Future<Result<void>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) => runApiCall(() async {
    await _dio.post<void>(
      '/auth/password/reset',
      data: {
        'phoneNumber': phoneNumber,
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  });
}
