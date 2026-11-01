import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/cache/response_cache.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/core/storage/token_storage.dart';
import 'package:mol_bhav/features/admin/presentation/admin_version_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_version_page.dart';
import 'package:mol_bhav/features/app_version/data/app_version_data.dart';
import 'package:mol_bhav/features/app_version/domain/app_version.dart';
import 'package:mol_bhav/features/app_version/presentation/app_version_cubit.dart';
import 'package:mol_bhav/features/app_version/presentation/update_gate.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AppVersionRepository {}

class _MockTokens extends Mock implements TokenStorage {}

class _MockCache extends Mock implements ResponseCache {}

class _FakeInstalled implements InstalledVersion {
  _FakeInstalled(this.version);

  final String? version;

  @override
  Future<String?> get() async => version;
}

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.signature';
}

const _policy = AppVersionPolicy(
  minimumVersion: '1.2.0',
  updateUrl: 'https://example.com/update',
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const AppVersionPolicy()));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.get()).thenAnswer((_) async => const Ok(_policy));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  group('versions', () {
    test('are read as three numbers, ignoring a build number or suffix', () {
      expect(parseVersion('1.2.3'), [1, 2, 3]);
      expect(parseVersion('1.2'), [1, 2, 0]);
      expect(parseVersion('0.1.0+1'), [0, 1, 0]);
      expect(parseVersion('2.0.0-beta'), [2, 0, 0]);
      expect(parseVersion('abc'), isNull);
      expect(parseVersion('1.2.3.4'), isNull);
      expect(parseVersion(''), isNull);
    });

    test('older means lower, comparing numbers rather than text', () {
      expect(isOlderThan('0.1.0+1', '1.0.0'), isTrue);
      expect(isOlderThan('1.9.0', '1.10.0'), isTrue);
      expect(isOlderThan('1.2.0', '1.2.0'), isFalse);
      expect(isOlderThan('1.2.1', '1.2.0'), isFalse);
      expect(isOlderThan('2.0.0', '1.99.99'), isFalse);
    });

    test('a value that cannot be read never counts as older', () {
      expect(isOlderThan('weird', '1.0.0'), isFalse);
      expect(isOlderThan('1.0.0', 'weird'), isFalse);
    });
  });

  group('parse', () {
    test('missing or blank values mean not set', () {
      expect(AppVersionRepositoryImpl.parse({}), const AppVersionPolicy());
      expect(
        AppVersionRepositoryImpl.parse({
          'minimumVersion': ' ',
          'updateUrl': '',
        }),
        const AppVersionPolicy(),
      );
    });

    test('reads both values', () {
      expect(
        AppVersionRepositoryImpl.parse({
          'minimumVersion': '1.2.0',
          'updateUrl': 'https://example.com/update',
        }),
        _policy,
      );
    });
  });

  group('AppVersionCubit', () {
    test('requires an update only when this build is older', () async {
      final old = AppVersionCubit(repository, _FakeInstalled('1.1.9'));
      addTearDown(old.close);
      await old.load();
      expect(old.state.updateRequired, isTrue);

      final current = AppVersionCubit(repository, _FakeInstalled('1.2.0+7'));
      addTearDown(current.close);
      await current.load();
      expect(current.state.updateRequired, isFalse);
    });

    test(
      'no minimum, or an unreadable installed version, blocks nobody',
      () async {
        when(() => repository.get())
            .thenAnswer((_) async => const Ok(AppVersionPolicy()));
        final none = AppVersionCubit(repository, _FakeInstalled('0.0.1'));
        addTearDown(none.close);
        await none.load();
        expect(none.state.updateRequired, isFalse);

        when(() => repository.get()).thenAnswer((_) async => const Ok(_policy));
        final unknown = AppVersionCubit(repository, _FakeInstalled(null));
        addTearDown(unknown.close);
        await unknown.load();
        expect(unknown.state.updateRequired, isFalse);
      },
    );

    test('a failed check keeps what was last known', () async {
      final cubit = AppVersionCubit(repository, _FakeInstalled('1.0.0'));
      addTearDown(cubit.close);
      await cubit.load();
      when(() => repository.get())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.updateRequired, isTrue);
    });

    test('a failed first check blocks nobody', () async {
      when(() => repository.get())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      final cubit = AppVersionCubit(repository, _FakeInstalled('0.0.1'));
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.updateRequired, isFalse);
      expect(cubit.state.installed, '0.0.1');
    });
  });

  group('UpdateGate', () {
    late SessionManager session;

    setUp(() {
      final tokens = _MockTokens();
      when(
        () => tokens.save(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});
      when(() => tokens.saveOnboarded(any())).thenAnswer((_) async {});
      final cache = _MockCache();
      session = SessionManager(tokens, cache);
    });

    Future<void> pump(WidgetTester tester, {required String installed}) async {
      final cubit = AppVersionCubit(repository, _FakeInstalled(installed));
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: UpdateGate(session: session, child: const Text('the app')),
        ),
      );
    }

    testWidgets('covers the app on an old build, with the update button', (
      tester,
    ) async {
      await pump(tester, installed: '1.0.0');

      expect(find.text('Please update MolBhav'), findsOneWidget);
      expect(find.textContaining('Your version 1.0.0'), findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);
    });

    testWidgets('leaves a current build alone', (tester) async {
      await pump(tester, installed: '1.2.0');

      expect(find.text('Please update MolBhav'), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('never covers an admin, so a mistake can be undone', (
      tester,
    ) async {
      await session.signIn(
        accessToken: _jwt({
          'role': ['user', 'admin'],
        }),
        refreshToken: 'r',
        onboarded: true,
      );

      await pump(tester, installed: '1.0.0');

      expect(find.text('Please update MolBhav'), findsNothing);
    });

    testWidgets('without an update link there is no button', (tester) async {
      when(() => repository.get()).thenAnswer(
        (_) async => const Ok(AppVersionPolicy(minimumVersion: '1.2.0')),
      );

      await pump(tester, installed: '1.0.0');

      expect(find.text('Please update MolBhav'), findsOneWidget);
      expect(find.text('Update now'), findsNothing);
    });
  });

  group('AdminVersionCubit', () {
    late AppVersionCubit userVersion;
    late AdminVersionCubit cubit;

    setUp(() {
      userVersion = AppVersionCubit(repository, _FakeInstalled('1.0.0'));
      cubit = AdminVersionCubit(repository, userVersion);
    });
    tearDown(() async {
      await cubit.close();
      await userVersion.close();
    });

    test('loads the saved policy', () async {
      await cubit.load();

      expect(cubit.state.policy.data, _policy);
    });

    test('a save is read back and refreshes this phone', () async {
      await cubit.save(_policy);

      verify(() => repository.save(_policy)).called(1);
      expect(cubit.state.saves, 1);
      expect(cubit.state.policy.data, _policy);
      expect(userVersion.state.updateRequired, isTrue);
    });

    test('a refused save is kept to be shown', () async {
      when(() => repository.save(any()))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.save(_policy);

      expect(cubit.state.saves, 0);
      expect(cubit.state.saveFailure, isA<NetworkFailure>());
      cubit.failureShown();
      expect(cubit.state.saveFailure, isNull);
    });
  });

  group('AdminVersionPage', () {
    Future<void> pump(WidgetTester tester) async {
      final userVersion = AppVersionCubit(repository, _FakeInstalled('1.0.0'));
      final cubit = AdminVersionCubit(repository, userVersion);
      addTearDown(() async {
        await cubit.close();
        await userVersion.close();
      });
      await userVersion.load();
      await cubit.load();
      await tester.pumpApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppVersionCubit>.value(value: userVersion),
            BlocProvider<AdminVersionCubit>.value(value: cubit),
          ],
          child: const AdminVersionPage(),
        ),
      );
    }

    testWidgets('shows the saved values and this app\'s version', (
      tester,
    ) async {
      await pump(tester);

      String valueOf(Finder field) =>
          tester.widget<TextField>(field).controller!.text;
      // (the hint "1.2.0" is also in the tree, so read the fields themselves)
      expect(valueOf(find.byType(TextField).first), '1.2.0');
      expect(
        valueOf(find.byType(TextField).last),
        'https://example.com/update',
      );
      expect(find.text('This app is version 1.0.0.'), findsOneWidget);
    });

    testWidgets('a version that is not dotted numbers cannot be saved', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '1.2.3.4');
      await tester.pump();

      expect(find.text('Use a version like 1.2.0.'), findsOneWidget);
      expect(tester.widget<MbButton>(find.byType(MbButton)).onPressed, isNull);
    });

    testWidgets('a link that is not a web address cannot be saved', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).last, 'play store');
      await tester.pump();

      expect(
        find.text('Use a web address starting with https://.'),
        findsOneWidget,
      );
      expect(tester.widget<MbButton>(find.byType(MbButton)).onPressed, isNull);
    });

    testWidgets('clearing both saves an empty policy (no minimum)', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.enterText(find.byType(TextField).last, '');
      await tester.pump();
      await tester.tap(find.byType(MbButton));
      await tester.pump();

      verify(() => repository.save(const AppVersionPolicy())).called(1);
    });
  });
}
