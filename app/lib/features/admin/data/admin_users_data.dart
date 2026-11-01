import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_call.dart';
import '../../../core/network/json.dart';
import '../domain/admin_users.dart';

/// `GET /admin/users`, `GET /admin/users/{id}`, `PUT /admin/users/{id}/status`.
@LazySingleton(as: AdminUsersRepository)
class AdminUsersRepositoryImpl implements AdminUsersRepository {
  AdminUsersRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AdminUser>>> getUsers({
    String? search,
    UserListFilter filter = UserListFilter.all,
    required int page,
    required int pageSize,
  }) => runApiCall(() async {
    final data = (await _dio.get<List<dynamic>>(
      '/admin/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'status': ?filter.wire,
        'page': page,
        'pageSize': pageSize,
      },
    )).data;
    return parseList(data ?? const [], parseUser);
  });

  @override
  Future<Result<AdminUserDetail>> getUser(String userId) =>
      runApiCall(() async {
        final j = (await _dio.get<Map<String, dynamic>>(
          '/admin/users/${Uri.encodeComponent(userId)}',
        )).data!;
        return parseDetail(j);
      });

  @override
  Future<Result<void>> setSuspended(String userId, {required bool suspend}) =>
      runApiCall(
        () => _dio.put<void>(
          '/admin/users/${Uri.encodeComponent(userId)}/status',
          data: {'action': suspend ? 'Suspend' : 'Reinstate'},
        ),
      );

  static AdminUser parseUser(Map<String, dynamic> j) => AdminUser(
    id: j.str('id'),
    phoneNumber: j.str('phoneNumber'),
    displayName: j.strOrNull('displayName'),
    isAdmin: j.str('role') == 'Admin',
    isSuspended: j.str('status') == 'Suspended',
    isPro: j.str('subscriptionTier') == 'Pro',
    state: j.strOrNull('state'),
    district: j.strOrNull('district'),
    businessType: j.strOrNull('businessType'),
    lastLoginAt: j.dateOrNull('lastLoginAtUtc'),
    createdAt: j.date('createdAtUtc'),
  );

  static AdminUserDetail parseDetail(Map<String, dynamic> j) {
    final sub = j.objOrNull('latestSubscription');
    return AdminUserDetail(
      user: parseUser(j.obj('user')),
      categories: j.strings('categories'),
      latestSubscription: sub == null
          ? null
          : AdminUserSubscription(
              planName: sub.str('planName'),
              status: sub.str('status'),
              expiresAt: sub.date('expiresAtUtc'),
            ),
      ticketsTotal: j.integer('ticketsTotal'),
      ticketsOpen: j.integer('ticketsOpen'),
    );
  }
}
