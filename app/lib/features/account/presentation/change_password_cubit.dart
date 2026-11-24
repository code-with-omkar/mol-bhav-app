import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/notifications/notification_service.dart';
import '../domain/account.dart';
import 'profile_cubit.dart';

/// More → Change password. The state is "a request is in flight".
///
/// A new password ends every session on the server, this phone included, so a
/// successful change signs out here too and the router returns to Login.
@injectable
class ChangePasswordCubit extends Cubit<bool> {
  ChangePasswordCubit(this._repository, this._profile, this._notifications)
    : super(false);

  final AccountRepository _repository;
  final ProfileCubit _profile;
  final NotificationService _notifications;

  /// Accounts that sign in another way and have no password yet set a first
  /// one without giving a current password.
  bool get hasPassword => _profile.state.data?.hasPassword ?? true;

  /// Null on success, else why the API refused (e.g. a wrong current password).
  Future<Failure?> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state) return null;
    emit(true);
    final result = await _repository.changePassword(
      currentPassword: hasPassword ? currentPassword : null,
      newPassword: newPassword,
    );
    if (!isClosed) emit(false);
    switch (result) {
      case Err<void>(:final failure):
        return failure;
      case Ok<void>():
        // Same order as Log out: drop the push token, then the session.
        await _notifications.dispose();
        await _repository.signOut();
        return null;
    }
  }
}
