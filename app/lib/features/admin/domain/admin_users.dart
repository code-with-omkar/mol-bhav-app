import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// A user as the admin list shows them.
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    required this.isAdmin,
    required this.isSuspended,
    required this.isPro,
    this.state,
    this.district,
    this.businessType,
    this.lastLoginAt,
    required this.createdAt,
  });

  final String id;
  final String phoneNumber;
  final String? displayName;
  final bool isAdmin;
  final bool isSuspended;
  final bool isPro;
  final String? state;
  final String? district;
  final String? businessType;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  /// The name when the user set one, else their phone number.
  String get title => (displayName == null || displayName!.trim().isEmpty)
      ? phoneNumber
      : displayName!;

  /// `Kolhapur, MH`, or whichever part is known.
  String? get place {
    final parts = [
      if (district != null && district!.isNotEmpty) district!,
      if (state != null && state!.isNotEmpty) state!,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    displayName,
    isAdmin,
    isSuspended,
    isPro,
    state,
    district,
    businessType,
    lastLoginAt,
    createdAt,
  ];
}

class AdminUserSubscription extends Equatable {
  const AdminUserSubscription({
    required this.planName,
    required this.status,
    required this.expiresAt,
  });

  final String planName;
  final String status;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [planName, status, expiresAt];
}

/// One user in full.
class AdminUserDetail extends Equatable {
  const AdminUserDetail({
    required this.user,
    required this.categories,
    this.latestSubscription,
    required this.ticketsTotal,
    required this.ticketsOpen,
  });

  final AdminUser user;
  final List<String> categories;
  final AdminUserSubscription? latestSubscription;
  final int ticketsTotal;
  final int ticketsOpen;

  @override
  List<Object?> get props => [
    user,
    categories,
    latestSubscription,
    ticketsTotal,
    ticketsOpen,
  ];
}

/// Which accounts the list shows.
enum UserListFilter {
  all,
  active,
  suspended;

  /// The API's status value, or `null` for everyone.
  String? get wire => switch (this) {
    UserListFilter.all => null,
    UserListFilter.active => 'Active',
    UserListFilter.suspended => 'Suspended',
  };
}

abstract interface class AdminUsersRepository {
  /// One page (1-based) of users, newest first. [search] matches part of the
  /// phone number or name.
  Future<Result<List<AdminUser>>> getUsers({
    String? search,
    UserListFilter filter = UserListFilter.all,
    required int page,
    required int pageSize,
  });

  Future<Result<AdminUserDetail>> getUser(String userId);

  /// Suspends ([suspend] true) or reinstates the account.
  Future<Result<void>> setSuspended(String userId, {required bool suspend});
}
