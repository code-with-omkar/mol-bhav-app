import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_mandis_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_mandis.dart';
import 'package:mol_bhav/features/admin/presentation/admin_mandis_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_mandis_page.dart';

import '../../helpers/pump_app.dart';

class _MockMandis extends Mock implements AdminMandisRepository {}

AdminMandi _mandi(String code, String name, {bool active = true}) => AdminMandi(
  id: 'id-$code',
  code: code,
  name: name,
  districtId: 'd1',
  districtName: 'Rajkot',
  isActive: active,
);

const _districts = [
  DistrictChoice(id: 'd1', label: 'Gujarat › Rajkot'),
  DistrictChoice(id: 'd2', label: 'Gujarat › Anand'),
];

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  test('the API answers are read', () {
    final mandi = AdminMandisRepositoryImpl.parseMandi({
      'id': 'm1',
      'code': 'rajkot',
      'name': 'Rajkot',
      'districtId': 'd1',
      'districtName': 'Rajkot',
      'isActive': false,
    });
    expect(mandi.isActive, isFalse);
    expect(mandi.districtName, 'Rajkot');

    final districts = AdminMandisRepositoryImpl.parseDistricts([
      {
        'name': 'Gujarat',
        'isActive': true,
        'districts': [
          {'id': 'd1', 'name': 'Rajkot', 'isActive': true},
          {'id': 'd2', 'name': 'Old', 'isActive': false},
        ],
      },
      {
        'name': 'Gone',
        'isActive': false,
        'districts': [
          {'id': 'd3', 'name': 'X', 'isActive': true},
        ],
      },
    ]);
    expect(districts, const [
      DistrictChoice(id: 'd1', label: 'Gujarat › Rajkot'),
    ]);
  });

  test('a new mandi needs a code, a name and a district', () {
    expect(
      mandiProblems(isNew: true, code: 'Bad', name: ' ', districtId: null),
      MandiProblem.values.toSet()..remove(MandiProblem.nameTooLong),
    );
    expect(
      mandiProblems(isNew: false, code: '', name: 'Rajkot', districtId: 'd1'),
      isEmpty,
    );
    expect(
      mandiProblems(isNew: false, code: '', name: 'a' * 151, districtId: 'd1'),
      {MandiProblem.nameTooLong},
    );
  });

  group('AdminMandisCubit', () {
    late _MockMandis repo;
    late AdminMandisCubit cubit;

    setUp(() {
      repo = _MockMandis();
      cubit = AdminMandisCubit(repo);
    });
    tearDown(() => cubit.close());

    void stubPage(int page, List<AdminMandi> rows) => when(
      () => repo.getMandis(
        page: page,
        pageSize: AdminMandisCubit.pageSize,
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Ok(rows));

    test('a full page means there may be more, and loadMore appends', () async {
      final first = [
        for (var i = 0; i < AdminMandisCubit.pageSize; i++)
          _mandi('m$i', 'M$i'),
      ];
      stubPage(1, first);
      stubPage(2, [_mandi('last', 'Last')]);

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();

      expect(cubit.state.mandis.length, first.length + 1);
      expect(cubit.state.hasMore, isFalse);
    });

    test('a search starts again from the first page', () async {
      stubPage(1, [_mandi('rajkot', 'Rajkot')]);

      await cubit.load(search: ' raj ');

      expect(cubit.state.search, 'raj');
      verify(
        () => repo.getMandis(
          page: 1,
          pageSize: AdminMandisCubit.pageSize,
          search: 'raj',
        ),
      ).called(1);
    });

    test('a failed first page is a failure', () async {
      when(
        () => repo.getMandis(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });

    test('a save rereads the list; a refusal is returned', () async {
      stubPage(1, [_mandi('rajkot', 'Rajkot')]);
      when(
        () => repo.updateMandi(
          id: any(named: 'id'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(
        await cubit.update(
          id: 'id-rajkot',
          name: 'Rajkot Yard',
          districtId: 'd1',
          isActive: true,
        ),
        isNull,
      );
      verify(
        () => repo.getMandis(
          page: 1,
          pageSize: AdminMandisCubit.pageSize,
          search: '',
        ),
      ).called(2);

      when(
        () => repo.createMandi(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
        ),
      ).thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(
        await cubit.create(code: 'x', name: 'X', districtId: 'd1'),
        isA<ServerFailure>(),
      );
    });
  });

  group('AdminMandisPage', () {
    late _MockMandis repo;

    setUp(() {
      repo = _MockMandis();
      when(
        () => repo.getMandis(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _mandi('rajkot', 'Rajkot'),
          _mandi('anand', 'Anand', active: false),
        ]),
      );
      when(() => repo.getDistricts())
          .thenAnswer((_) async => const Ok(_districts));
      when(
        () => repo.updateMandi(
          id: any(named: 'id'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.createMandi(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
        ),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminMandisCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminMandisPage()),
      );
    }

    testWidgets('lists mandis and marks the switched-off ones', (tester) async {
      await pump(tester);

      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Anand'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('submitting the search asks for that term', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'raj');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      verify(() => repo.getMandis(page: 1, pageSize: 30, search: 'raj'))
          .called(1);
    });

    testWidgets('rename a mandi, move it and switch it off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Rajkot'));
      await tester.pumpAndSettle();
      expect(find.text('Edit mandi'), findsOneWidget);
      // The code is fixed once the mandi exists.
      expect(find.text('Code'), findsNothing);

      // Fields: search, then name.
      await tester.enterText(find.byType(TextField).last, 'Rajkot Yard');
      await tapVisible(tester, find.text('Gujarat › Rajkot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat › Anand'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateMandi(
          id: 'id-rajkot',
          name: 'Rajkot Yard',
          districtId: 'd2',
          isActive: false,
        ),
      ).called(1);
      expect(find.text('Edit mandi'), findsNothing);
    });

    testWidgets('add a mandi', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New mandi'));
      await tester.pumpAndSettle();
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 2), 'gondal');
      await tester.enterText(find.byType(TextField).at(count - 1), 'Gondal');
      await tapVisible(tester, find.text('Choose a district'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat › Rajkot'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () =>
            repo.createMandi(code: 'gondal', name: 'Gondal', districtId: 'd1'),
      ).called(1);
    });

    testWidgets('a new mandi needs everything before it is sent', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New mandi'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text("Enter the mandi's name."), findsOneWidget);
      expect(find.text('Choose a district.'), findsOneWidget);
      verifyNever(
        () => repo.createMandi(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
        ),
      );
    });

    testWidgets('a taken code is refused and the sheet stays open', (
      tester,
    ) async {
      when(
        () => repo.createMandi(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Code already used.')),
      );
      await pump(tester);

      await tester.tap(find.text('New mandi'));
      await tester.pumpAndSettle();
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 2), 'rajkot');
      await tester.enterText(find.byType(TextField).at(count - 1), 'Rajkot');
      await tapVisible(tester, find.text('Choose a district'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat › Rajkot'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Code already used.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
