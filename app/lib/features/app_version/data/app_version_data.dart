import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../domain/app_version.dart';

/// `GET /app-version` (public) and `PUT /app-version` (admin). Empty values
/// are left out of the answer, so a missing key means "not set".
@LazySingleton(as: AppVersionRepository)
class AppVersionRepositoryImpl implements AppVersionRepository {
  AppVersionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AppVersionPolicy>> get() => runApiCall(
    () async =>
        parse((await _dio.get<Map<String, dynamic>>('/app-version')).data!),
  );

  @override
  Future<Result<void>> save(AppVersionPolicy policy) => runApiCall(
    () => _dio.put<void>(
      '/app-version',
      data: {
        'minimumVersion': policy.minimumVersion ?? '',
        'updateUrl': policy.updateUrl ?? '',
      },
    ),
  );

  static AppVersionPolicy parse(Map<String, dynamic> j) {
    String? text(String key) {
      final v = j[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return AppVersionPolicy(
      minimumVersion: text('minimumVersion'),
      updateUrl: text('updateUrl'),
    );
  }
}

/// This build's `version:` from pubspec (the part before the `+`).
@LazySingleton(as: InstalledVersion)
class PackageInfoInstalledVersion implements InstalledVersion {
  @override
  Future<String?> get() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } on Object {
      // Without a readable version nobody can be called out of date.
      return null;
    }
  }
}
