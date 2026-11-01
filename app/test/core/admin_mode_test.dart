import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/session/admin_mode.dart';
import 'package:mol_bhav/core/session/jwt_roles.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/core/storage/token_storage.dart';

class _MockTokens extends Mock implements TokenStorage {}

class _MockCache extends Mock implements ResponseCache {}

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.signature';
}

void main() {
  group('tokenHasRole', () {
    test('a role claim as a string', () {
      expect(tokenHasRole(_jwt({'role': 'Admin'}), 'Admin'), isTrue);
      expect(tokenHasRole(_jwt({'role': 'User'}), 'Admin'), isFalse);
    });

    test('a role claim as a list', () {
      expect(
        tokenHasRole(
          _jwt({
            'role': ['User', 'Admin'],
          }),
          'Admin',
        ),
        isTrue,
      );
    });

    test('the API issues lower-case roles, which still match', () {
      expect(
        tokenHasRole(
          _jwt({
            'role': ['user', 'admin'],
          }),
          'Admin',
        ),
        isTrue,
      );
      expect(tokenHasRole(_jwt({'role': 'user'}), 'Admin'), isFalse);
    });

    test('no claim, no token or a malformed token is not an admin', () {
      expect(tokenHasRole(_jwt({'sub': '1'}), 'Admin'), isFalse);
      expect(tokenHasRole(null, 'Admin'), isFalse);
      expect(tokenHasRole('not-a-jwt', 'Admin'), isFalse);
      expect(tokenHasRole('a.@@@.c', 'Admin'), isFalse);
    });
  });

  group('AdminMode', () {
    late SessionManager session;
    late AdminMode mode;

    setUp(() {
      final tokens = _MockTokens();
      when(
        () => tokens.save(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});
      when(() => tokens.saveOnboarded(any())).thenAnswer((_) async {});
      when(tokens.clear).thenAnswer((_) async {});
      final cache = _MockCache();
      when(cache.clear).thenAnswer((_) async {});
      session = SessionManager(tokens, cache);
      mode = AdminMode(session);
    });

    Future<void> signIn(String role) => session.signIn(
      accessToken: _jwt({'role': role}),
      refreshToken: 'r',
      onboarded: true,
    );

    test('an admin starts in the admin app', () async {
      await signIn('Admin');

      expect(session.isAdmin, isTrue);
      expect(mode.inAdminApp, isTrue);
    });

    test('a normal user is never in the admin app', () async {
      await signIn('User');

      expect(session.isAdmin, isFalse);
      expect(mode.inAdminApp, isFalse);
    });

    test('an admin can switch to the user app and back', () async {
      await signIn('Admin');
      var changes = 0;
      mode.addListener(() => changes++);

      mode.switchToUserView();
      expect(mode.inAdminApp, isFalse);

      mode.switchToAdminView();
      expect(mode.inAdminApp, isTrue);
      expect(changes, 2);
    });

    test(
      'signing out forgets the choice, so the next login starts in admin',
      () async {
        await signIn('Admin');
        mode.switchToUserView();

        await session.signOut();
        expect(session.isAdmin, isFalse);
        expect(mode.userView, isFalse);

        await signIn('Admin');
        expect(mode.inAdminApp, isTrue);
      },
    );
  });
}
