import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/notifications/notification_service.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/features/account/domain/account.dart';
import 'package:mol_bhav/features/account/presentation/change_password_cubit.dart';
import 'package:mol_bhav/features/account/presentation/profile_cubit.dart';
import 'package:mol_bhav/features/admin/domain/admin_users.dart';
import 'package:mol_bhav/features/admin/presentation/admin_user_detail_cubit.dart';

class _MockAccount extends Mock implements AccountRepository {}

class _MockProfile extends Mock implements ProfileCubit {}

class _MockNotifications extends Mock implements NotificationService {}

class _MockAdminUsers extends Mock implements AdminUsersRepository {}

AccountProfile _profile({required bool hasPassword}) => AccountProfile(
  name: 'A',
  phoneNumberMasked: '******3210',
  userId: 'u1',
  businessTypeName: '',
  districtName: '',
  stateName: '',
  categoryCodes: const [],
  categoryNames: const [],
  isPro: false,
  pushEnabled: false,
  whatsappEnabled: false,
  hasPassword: hasPassword,
);

void main() {
  group('newPasswordProblems', () {
    test('needs 8 characters, a letter and a number', () {
      Set<NewPasswordProblem> check(String p) =>
          newPasswordProblems(current: '', password: p, confirm: p);

      expect(check('short1'), {NewPasswordProblem.tooWeak});
      expect(check('onlyletters'), {NewPasswordProblem.tooWeak});
      expect(check('12345678'), {NewPasswordProblem.tooWeak});
      expect(check('goodpass12'), isEmpty);
    });

    test('must differ from the current one and match the confirmation', () {
      expect(
        newPasswordProblems(
          current: 'goodpass12',
          password: 'goodpass12',
          confirm: 'goodpass12',
        ),
        {NewPasswordProblem.sameAsCurrent},
      );
      expect(
        newPasswordProblems(
          current: 'old',
          password: 'goodpass12',
          confirm: 'other1234',
        ),
        {NewPasswordProblem.mismatch},
      );
    });
  });

  group('ChangePasswordCubit', () {
    late _MockAccount repo;
    late _MockProfile profile;
    late _MockNotifications notifications;

    setUp(() {
      repo = _MockAccount();
      profile = _MockProfile();
      notifications = _MockNotifications();
      when(() => repo.signOut()).thenAnswer((_) async {});
      when(() => notifications.dispose()).thenAnswer((_) async {});
    });

    void stubChange() => when(
      () => repo.changePassword(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    test('sends the current password when the account has one', () async {
      when(() => profile.state)
          .thenReturn(DataState.ready(_profile(hasPassword: true)));
      stubChange();
      final cubit = ChangePasswordCubit(repo, profile, notifications);

      final failure = await cubit.submit(
        currentPassword: 'oldpass1',
        newPassword: 'newpass12',
      );

      expect(failure, isNull);
      verify(
        () => repo.changePassword(
          currentPassword: 'oldpass1',
          newPassword: 'newpass12',
        ),
      ).called(1);
      // Every session ends with a new password, so this phone signs out too.
      verify(() => repo.signOut()).called(1);
    });

    test('an account without a password sets a first one', () async {
      when(() => profile.state)
          .thenReturn(DataState.ready(_profile(hasPassword: false)));
      stubChange();
      final cubit = ChangePasswordCubit(repo, profile, notifications);

      await cubit.submit(currentPassword: '', newPassword: 'newpass12');

      expect(cubit.hasPassword, isFalse);
      verify(
        () => repo.changePassword(newPassword: 'newpass12'),
      ).called(1);
    });

    test('a refusal is returned', () async {
      when(() => profile.state)
          .thenReturn(DataState.ready(_profile(hasPassword: true)));
      when(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Wrong password.')),
      );
      final cubit = ChangePasswordCubit(repo, profile, notifications);

      final failure = await cubit.submit(
        currentPassword: 'bad',
        newPassword: 'newpass12',
      );

      expect(failure, isA<ServerFailure>());
      verifyNever(() => repo.signOut());
    });
  });

  group('AdminUserDetailCubit.resetPassword', () {
    late _MockAdminUsers repo;

    setUp(() => repo = _MockAdminUsers());

    test('returns the temporary password', () async {
      when(() => repo.resetPassword('u1'))
          .thenAnswer((_) async => const Ok('Temp1234abcd'));
      final cubit = AdminUserDetailCubit(repo);

      expect(await cubit.resetPassword('u1'), 'Temp1234abcd');
      expect(cubit.state.busy, isFalse);
    });

    test('a refusal is kept as the action failure', () async {
      when(() => repo.resetPassword('u1')).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Not allowed.')),
      );
      final cubit = AdminUserDetailCubit(repo);

      expect(await cubit.resetPassword('u1'), isNull);
      expect(cubit.state.actionFailure, isA<ServerFailure>());
    });
  });
}
