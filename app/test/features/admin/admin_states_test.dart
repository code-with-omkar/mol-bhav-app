import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_states_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_states.dart';
import 'package:mol_bhav/features/admin/presentation/admin_states_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_states_page.dart';

import '../../helpers/pump_app.dart';

class _MockStates extends Mock implements AdminStatesRepository {}

const _gujarat = AdminState(
  id: 's1',
  name: 'Gujarat',
  code: 'GJ',
  isActive: true,
  districts: [
    AdminDistrict(id: 'd1', name: 'Rajkot', isActive: true),
    AdminDistrict(id: 'd2', name: 'Anand', isActive: false),
  ],
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  test('the API answer is read, with districts', () {
    final state = AdminStatesRepositoryImpl.parseState({
      'id': 's1',
      'name': 'Gujarat',
      'code': 'GJ',
      'isActive': false,
      'districts': [
        {'id': 'd1', 'name': 'Rajkot', 'isActive': true},
      ],
    });

    expect(state.code, 'GJ');
    expect(state.isActive, isFalse);
    expect(state.districts.single.name, 'Rajkot');
  });

  test('a state code is 2 to 10 letters or digits', () {
    expect(isValidStateCode('MH'), isTrue);
    expect(isValidStateCode(' gj '), isTrue);
    expect(isValidStateCode('M'), isFalse);
    expect(isValidStateCode('MAHARASHTRA1'), isFalse);
    expect(isValidStateCode('M-H'), isFalse);
  });

  test('a name is needed; a code only for a new state', () {
    expect(placeProblems(name: ' ', needsCode: true, code: 'x'), {
      PlaceProblem.nameMissing,
      PlaceProblem.codeInvalid,
    });
    expect(placeProblems(name: 'Gujarat', needsCode: false), isEmpty);
    expect(placeProblems(name: 'a' * 101, needsCode: false), {
      PlaceProblem.nameTooLong,
    });
  });

  group('AdminStatesCubit', () {
    late _MockStates repo;
    late AdminStatesCubit cubit;

    setUp(() {
      repo = _MockStates();
      when(() => repo.getStates())
          .thenAnswer((_) async => const Ok([_gujarat]));
      cubit = AdminStatesCubit(repo);
    });
    tearDown(() => cubit.close());

    test('loads the states', () async {
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.data, [_gujarat]);
    });

    test('a save rereads the list; a refusal is returned', () async {
      when(
        () => repo.createState(
          name: any(named: 'name'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(await cubit.createState('Goa', 'GA'), isNull);
      verify(() => repo.getStates()).called(2);

      when(
        () => repo.addDistrict(
          stateId: any(named: 'stateId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(await cubit.addDistrict('s1', 'X'), isA<ServerFailure>());
    });
  });

  group('AdminStatesPage', () {
    late _MockStates repo;

    setUp(() {
      repo = _MockStates();
      when(() => repo.getStates())
          .thenAnswer((_) async => const Ok([_gujarat]));
      when(
        () => repo.createState(
          name: any(named: 'name'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.updateState(
          id: any(named: 'id'),
          name: any(named: 'name'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.addDistrict(
          stateId: any(named: 'stateId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.updateDistrict(
          stateId: any(named: 'stateId'),
          id: any(named: 'id'),
          name: any(named: 'name'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminStatesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminStatesPage()),
      );
    }

    testWidgets('shows a state with its districts', (tester) async {
      await pump(tester);

      expect(find.text('Gujarat'), findsOneWidget);
      expect(find.text('GJ'), findsOneWidget);
      expect(find.text('› Rajkot'), findsOneWidget);
      expect(find.text('› Anand'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('rename a state and switch it off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Gujarat'));
      await tester.pumpAndSettle();
      expect(find.text('Edit state'), findsOneWidget);
      // No code field when editing.
      expect(find.text('Code'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Gujarat State');
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () =>
            repo.updateState(id: 's1', name: 'Gujarat State', isActive: false),
      ).called(1);
    });

    testWidgets('switch a district back on', (tester) async {
      await pump(tester);

      await tester.tap(find.text('› Anand'));
      await tester.pumpAndSettle();
      expect(find.text('Edit district'), findsOneWidget);
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateDistrict(
          stateId: 's1',
          id: 'd2',
          name: 'Anand',
          isActive: true,
        ),
      ).called(1);
    });

    testWidgets('add a district under its state', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New district'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Gondal');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => repo.addDistrict(stateId: 's1', name: 'Gondal')).called(1);
    });

    testWidgets('add a state with its code', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New state'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Goa');
      await tester.enterText(find.byType(TextField).at(1), 'ga');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => repo.createState(name: 'Goa', code: 'ga')).called(1);
    });

    testWidgets('a new state needs a name and a valid code', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New state'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Use 2 to 10 letters or digits.'), findsOneWidget);
      verifyNever(
        () => repo.createState(
          name: any(named: 'name'),
          code: any(named: 'code'),
        ),
      );
    });

    testWidgets('a refused save stays open and says why', (tester) async {
      when(
        () => repo.createState(
          name: any(named: 'name'),
          code: any(named: 'code'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'State already exists.')),
      );
      await pump(tester);

      await tester.tap(find.text('New state'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Gujarat');
      await tester.enterText(find.byType(TextField).at(1), 'GJ');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('State already exists.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
