import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_units_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_products.dart';
import 'package:mol_bhav/features/admin/domain/admin_units.dart';
import 'package:mol_bhav/features/admin/presentation/admin_units_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_units_page.dart';

import '../../helpers/pump_app.dart';

class _MockUnits extends Mock implements AdminUnitsRepository {}

const _qtl = AdminUnit(
  id: 'u1',
  code: 'qtl',
  symbol: 'qtl',
  dimension: UnitDimension.mass,
  toBaseFactor: 100,
  isActive: true,
  translations: [
    ProductTranslation(language: 'en', name: 'Quintal', description: 'Q'),
    ProductTranslation(language: 'gu', name: 'ક્વિન્ટલ'),
  ],
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_qtl);
    registerFallbackValue(UnitDimension.mass);
  });

  test('the API answer is read', () {
    final unit = AdminUnitsRepositoryImpl.parseUnit({
      'id': 'u1',
      'code': 'qtl',
      'symbol': 'qtl',
      'dimension': 'Mass',
      'toBaseFactor': 100,
      'isActive': false,
      'translations': [
        {'languageCode': 'en', 'name': 'Quintal', 'description': null},
      ],
    });

    expect(unit.dimension, UnitDimension.mass);
    expect(unit.toBaseFactor, 100);
    expect(unit.isActive, isFalse);
    expect(unit.label, 'Quintal');
    // An unknown dimension reads as the generic one.
    expect(UnitDimension.fromWire('Weird'), UnitDimension.count);
  });

  test('editing keeps the code, dimension, factor, other languages', () {
    final edited = _qtl.edited(
      symbol: ' q ',
      names: {'en': 'Quintal', 'hi': 'क्विंटल', 'mr': ''},
      isActive: false,
    );

    expect(edited.symbol, 'q');
    expect(edited.nameIn('hi'), 'क्विंटल');
    expect(edited.nameIn('gu'), 'ક્વિન્ટલ');
    expect(edited.isActive, isFalse);
    expect(edited.code, 'qtl');
    expect(edited.dimension, UnitDimension.mass);
    expect(edited.toBaseFactor, 100);
  });

  test('a factor is a positive number with up to six decimals', () {
    expect(parseUnitFactor('100'), 100);
    expect(parseUnitFactor(' 0.5 '), 0.5);
    expect(parseUnitFactor('0.000001'), 0.000001);
    expect(parseUnitFactor('0'), isNull);
    expect(parseUnitFactor('0.0000001'), isNull);
    expect(parseUnitFactor('1.2.3'), isNull);
    expect(parseUnitFactor('abc'), isNull);
    expect(parseUnitFactor(''), isNull);
  });

  test('a new unit needs everything; an existing one only symbol and name', () {
    expect(
      unitProblems(
        isNew: true,
        code: 'Bad',
        symbol: '',
        factor: '',
        names: {'en': ''},
      ),
      {
        UnitProblem.codeInvalid,
        UnitProblem.symbolInvalid,
        UnitProblem.englishMissing,
        UnitProblem.factorInvalid,
      },
    );
    expect(
      unitProblems(
        isNew: false,
        code: '',
        symbol: 'qtl',
        factor: '',
        names: {'en': 'Quintal'},
      ),
      isEmpty,
    );
    expect(
      unitProblems(
        isNew: false,
        code: '',
        symbol: 'x' * 17,
        factor: '',
        names: {'en': 'Q'},
      ),
      {UnitProblem.symbolInvalid},
    );
  });

  group('AdminUnitsCubit', () {
    late _MockUnits repo;
    late AdminUnitsCubit cubit;

    setUp(() {
      repo = _MockUnits();
      when(() => repo.getUnits()).thenAnswer((_) async => const Ok([_qtl]));
      cubit = AdminUnitsCubit(repo);
    });
    tearDown(() => cubit.close());

    test('loads the units', () async {
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.data, [_qtl]);
    });

    test('a save rereads the list; a refusal is returned', () async {
      when(() => repo.updateUnit(any()))
          .thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(await cubit.update(_qtl), isNull);
      verify(() => repo.getUnits()).called(2);

      when(() => repo.updateUnit(any()))
          .thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(await cubit.update(_qtl), isA<ServerFailure>());
    });
  });

  group('AdminUnitsPage', () {
    late _MockUnits repo;

    setUp(() {
      repo = _MockUnits();
      when(() => repo.getUnits()).thenAnswer((_) async => const Ok([_qtl]));
      when(() => repo.updateUnit(any()))
          .thenAnswer((_) async => const Ok(null));
      when(
        () => repo.createUnit(
          code: any(named: 'code'),
          symbol: any(named: 'symbol'),
          dimension: any(named: 'dimension'),
          toBaseFactor: any(named: 'toBaseFactor'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminUnitsCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminUnitsPage()),
      );
    }

    testWidgets('shows a unit with what it measures and its factor', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Quintal (qtl)'), findsOneWidget);
      expect(find.textContaining('1 = 100 kg'), findsOneWidget);
    });

    testWidgets('rename a unit and switch it off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Quintal (qtl)'));
      await tester.pumpAndSettle();
      expect(find.text('Edit unit'), findsOneWidget);
      // The code, what it measures and the factor are fixed.
      expect(find.text('Code'), findsNothing);
      expect(find.text('What it measures'), findsNothing);

      // Fields: symbol, English, Hindi, Marathi.
      await tester.enterText(find.byType(TextField).at(2), 'क्विंटल');
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repo.updateUnit(captureAny())).captured.single
              as AdminUnit;
      expect(saved.nameIn('hi'), 'क्विंटल');
      expect(saved.isActive, isFalse);
      expect(saved.nameIn('gu'), 'ક્વિન્ટલ');
      expect(find.text('Edit unit'), findsNothing);
    });

    testWidgets('add a unit', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New unit'));
      await tester.pumpAndSettle();
      // Fields: code, symbol, English, Hindi, Marathi, factor.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'bag-50kg');
      await tester.enterText(fields.at(1), 'bag');
      await tester.enterText(fields.at(2), 'Bag of 50 kg');
      await tapVisible(tester, find.text('Choose what it measures'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(5), '50');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.createUnit(
          code: 'bag-50kg',
          symbol: 'bag',
          dimension: UnitDimension.mass,
          toBaseFactor: 50,
          names: {'en': 'Bag of 50 kg', 'hi': '', 'mr': ''},
        ),
      ).called(1);
    });

    testWidgets('a new unit needs everything before it is sent', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New unit'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the English name.'), findsOneWidget);
      expect(find.text('Choose what the unit measures.'), findsOneWidget);
      expect(
        find.text('Enter a number above zero, with up to 6 decimals.'),
        findsOneWidget,
      );
      verifyNever(
        () => repo.createUnit(
          code: any(named: 'code'),
          symbol: any(named: 'symbol'),
          dimension: any(named: 'dimension'),
          toBaseFactor: any(named: 'toBaseFactor'),
          names: any(named: 'names'),
        ),
      );
    });

    testWidgets('a refused save stays open and says why', (tester) async {
      when(() => repo.updateUnit(any())).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Unit is locked.')),
      );
      await pump(tester);

      await tester.tap(find.text('Quintal (qtl)'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Unit is locked.'), findsOneWidget);
      expect(find.text('Edit unit'), findsOneWidget);
    });
  });
}
