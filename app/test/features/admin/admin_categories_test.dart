import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_categories_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_categories.dart';
import 'package:mol_bhav/features/admin/domain/admin_products.dart';
import 'package:mol_bhav/features/admin/presentation/admin_categories_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_categories_page.dart';

import '../../helpers/pump_app.dart';

class _MockCategories extends Mock implements AdminCategoriesRepository {}

const _roots = AdminSubCategory(
  id: 'sc1',
  code: 'roots',
  displayOrder: 2,
  isActive: true,
  translations: [ProductTranslation(language: 'en', name: 'Roots')],
);

const _veg = AdminCategory(
  id: 'c1',
  code: 'veg',
  iconKey: 'leaf',
  displayOrder: 1,
  isActive: true,
  translations: [
    ProductTranslation(
      language: 'en',
      name: 'Vegetables',
      description: 'Fresh',
    ),
    ProductTranslation(language: 'gu', name: 'શાકભાજી'),
  ],
  subCategories: [_roots],
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_veg);
    registerFallbackValue(_roots);
  });

  test('the API answer is read, with sub-categories', () {
    final category = AdminCategoriesRepositoryImpl.parseCategory({
      'id': 'c1',
      'code': 'veg',
      'iconKey': null,
      'displayOrder': 1,
      'isActive': false,
      'translations': [
        {'languageCode': 'en', 'name': 'Vegetables', 'description': null},
      ],
      'subCategories': [
        {
          'id': 'sc1',
          'code': 'roots',
          'displayOrder': 0,
          'isActive': true,
          'translations': [],
        },
      ],
    });

    expect(category.label, 'Vegetables');
    expect(category.isActive, isFalse);
    expect(category.subCategories.single.label, 'roots'); // no name: the code
  });

  test(
    'editing keeps other languages, descriptions and the sub-categories',
    () {
      final edited = _veg.edited(
        names: {'en': 'Veggies', 'hi': 'सब्ज़ी', 'mr': ''},
        isActive: false,
      );

      expect(edited.nameIn('en'), 'Veggies');
      expect(edited.nameIn('hi'), 'सब्ज़ी');
      expect(edited.nameIn('gu'), 'શાકભાજી');
      expect(edited.translations.first.description, 'Fresh');
      expect(edited.isActive, isFalse);
      expect(edited.iconKey, 'leaf');
      expect(edited.subCategories, [_roots]);
    },
  );

  test('a new item needs a valid code and an English name', () {
    expect(categoryProblems(isNew: true, code: 'Bad Code', names: {'en': ''}), {
      CategoryProblem.codeInvalid,
      CategoryProblem.englishMissing,
    });
    // The code is fixed once the item exists.
    expect(
      categoryProblems(isNew: false, code: '', names: {'en': 'Veg'}),
      isEmpty,
    );
    expect(categoryProblems(isNew: false, code: '', names: {'en': 'a' * 121}), {
      CategoryProblem.tooLong,
    });
  });

  group('AdminCategoriesCubit', () {
    late _MockCategories repo;
    late AdminCategoriesCubit cubit;

    setUp(() {
      repo = _MockCategories();
      when(() => repo.getCategories())
          .thenAnswer((_) async => const Ok([_veg]));
      cubit = AdminCategoriesCubit(repo);
    });
    tearDown(() => cubit.close());

    test('loads the categories', () async {
      await cubit.load();

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.data, [_veg]);
    });

    test('a save rereads the list; a refusal is returned', () async {
      when(
        () => repo.createCategory(
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(await cubit.createCategory('fruit', {'en': 'Fruit'}), isNull);
      verify(() => repo.getCategories()).called(2);

      when(() => repo.updateCategory(any()))
          .thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(await cubit.updateCategory(_veg), isA<ServerFailure>());
    });

    test('sub-categories are added and changed under their category', () async {
      when(
        () => repo.addSubCategory(
          categoryId: any(named: 'categoryId'),
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.updateSubCategory(
          categoryId: any(named: 'categoryId'),
          subCategory: any(named: 'subCategory'),
        ),
      ).thenAnswer((_) async => const Ok(null));

      await cubit.addSubCategory('c1', 'leafy', {'en': 'Leafy'});
      await cubit.updateSubCategory('c1', _roots);

      verify(
        () => repo.addSubCategory(
          categoryId: 'c1',
          code: 'leafy',
          names: {'en': 'Leafy'},
        ),
      ).called(1);
      verify(
        () => repo.updateSubCategory(categoryId: 'c1', subCategory: _roots),
      ).called(1);
    });
  });

  group('AdminCategoriesPage', () {
    late _MockCategories repo;

    setUp(() {
      repo = _MockCategories();
      when(() => repo.getCategories())
          .thenAnswer((_) async => const Ok([_veg]));
      when(
        () => repo.createCategory(
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(() => repo.updateCategory(any()))
          .thenAnswer((_) async => const Ok(null));
      when(
        () => repo.addSubCategory(
          categoryId: any(named: 'categoryId'),
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.updateSubCategory(
          categoryId: any(named: 'categoryId'),
          subCategory: any(named: 'subCategory'),
        ),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminCategoriesCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminCategoriesPage()),
      );
    }

    testWidgets('shows a category with its sub-categories', (tester) async {
      await pump(tester);

      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('veg'), findsOneWidget);
      expect(find.textContaining('› Roots'), findsOneWidget);
    });

    testWidgets('rename a category and switch it off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Vegetables'));
      await tester.pumpAndSettle();
      expect(find.text('Edit category'), findsOneWidget);
      // No code field when editing.
      expect(find.text('Code'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Veggies');
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repo.updateCategory(captureAny())).captured.single
              as AdminCategory;
      expect(saved.nameIn('en'), 'Veggies');
      expect(saved.isActive, isFalse);
      expect(saved.nameIn('gu'), 'શાકભાજી');
      expect(find.text('Edit category'), findsNothing);
    });

    testWidgets('edit a sub-category', (tester) async {
      await pump(tester);

      await tester.tap(find.textContaining('› Roots'));
      await tester.pumpAndSettle();
      expect(find.text('Edit sub-category'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'मूल');
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => repo.updateSubCategory(
                  categoryId: 'c1',
                  subCategory: captureAny(named: 'subCategory'),
                ),
              ).captured.single
              as AdminSubCategory;
      expect(captured.nameIn('mr'), 'मूल');
      expect(captured.nameIn('en'), 'Roots');
    });

    testWidgets('add a category', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'fruit');
      await tester.enterText(find.byType(TextField).at(1), 'Fruit');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.createCategory(
          code: 'fruit',
          names: {'en': 'Fruit', 'hi': '', 'mr': ''},
        ),
      ).called(1);
    });

    testWidgets('add a sub-category under its category', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New sub-category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'leafy');
      await tester.enterText(find.byType(TextField).at(1), 'Leafy');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.addSubCategory(
          categoryId: 'c1',
          code: 'leafy',
          names: {'en': 'Leafy', 'hi': '', 'mr': ''},
        ),
      ).called(1);
    });

    testWidgets('a new item needs a code and an English name', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the English name.'), findsOneWidget);
      expect(find.textContaining('lowercase letters, digits'), findsWidgets);
      verifyNever(
        () => repo.createCategory(
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      );
    });

    testWidgets('a taken code is refused and the sheet stays open', (
      tester,
    ) async {
      when(
        () => repo.createCategory(
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Code already used.')),
      );
      await pump(tester);

      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'veg');
      await tester.enterText(find.byType(TextField).at(1), 'Veg');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Code already used.'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('a failed load can be retried', (tester) async {
      when(() => repo.getCategories())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      when(() => repo.getCategories())
          .thenAnswer((_) async => const Ok([_veg]));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Vegetables'), findsOneWidget);
    });
  });
}
