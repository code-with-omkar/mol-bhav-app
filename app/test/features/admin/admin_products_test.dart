import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_products_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_commodities.dart';
import 'package:mol_bhav/features/admin/domain/admin_products.dart';
import 'package:mol_bhav/features/admin/presentation/admin_products_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_products_page.dart';

import '../../helpers/pump_app.dart';

class _MockProducts extends Mock implements AdminProductsRepository {}

class _MockCommodities extends Mock implements AdminCommoditiesRepository {}

AdminProductSummary _summary(String code, String name, {bool active = true}) =>
    AdminProductSummary(
      id: 'id-$code',
      code: code,
      name: name,
      categoryCode: 'veg',
      subCategoryCode: 'roots',
      unitCode: 'qtl',
      isActive: active,
    );

const _onion = AdminProduct(
  id: 'id-onion',
  code: 'onion',
  subCategoryId: 'sc1',
  defaultUnitId: 'u1',
  displayOrder: 3,
  isActive: true,
  imageKey: 'onion.png',
  translations: [
    ProductTranslation(language: 'en', name: 'Onion', description: 'Red'),
    ProductTranslation(language: 'hi', name: 'प्याज़'),
    ProductTranslation(language: 'gu', name: 'ડુંગળી'),
  ],
  variants: [
    AdminVariant(
      id: 'v1',
      code: 'large',
      displayOrder: 1,
      isActive: true,
      translations: [ProductTranslation(language: 'en', name: 'Large')],
    ),
  ],
);

const _targets = CommodityTargets(
  subCategories: [CatalogChoice(id: 'sc1', label: 'Vegetables › Roots')],
  units: [CatalogChoice(id: 'u1', label: 'Quintal (qtl)')],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_onion);
    registerFallbackValue(_onion.variants.first);
  });

  _variantUnitTests();

  test('a product code follows the catalog rule', () {
    expect(isValidProductCode('red-onion'), isTrue);
    expect(isValidProductCode(' onion2 '), isTrue);
    expect(isValidProductCode('Onion'), isFalse);
    expect(isValidProductCode('1onion'), isFalse);
    expect(isValidProductCode('red onion'), isFalse);
    expect(isValidProductCode(''), isFalse);
    expect(isValidProductCode('a' * 41), isFalse);
  });

  test(
    'a new product needs a code, an English name, a sub-category and unit',
    () {
      expect(
        newProductProblems(
          code: '',
          names: {'en': ''},
          subCategoryId: null,
          unitId: null,
        ),
        NewProductProblem.values.toSet(),
      );
      expect(
        newProductProblems(
          code: 'onion',
          names: {'en': 'Onion'},
          subCategoryId: 'sc1',
          unitId: 'u1',
        ),
        isEmpty,
      );
    },
  );

  group('AdminProduct.edited', () {
    test('changes the names, keeps other languages and descriptions', () {
      final edited = _onion.edited(
        names: {'en': ' Onion Red ', 'hi': 'प्याज', 'mr': 'कांदा'},
        isActive: false,
      );

      expect(edited.isActive, isFalse);
      expect(edited.nameIn('en'), 'Onion Red');
      expect(edited.nameIn('hi'), 'प्याज');
      expect(edited.nameIn('mr'), 'कांदा');
      expect(edited.nameIn('gu'), 'ડુંગળી');
      expect(
        edited.translations.firstWhere((t) => t.language == 'en').description,
        'Red',
      );
      // Everything else rides along for the full-replacement update.
      expect(edited.imageKey, 'onion.png');
      expect(edited.displayOrder, 3);
      expect(edited.subCategoryId, 'sc1');
    });

    test('a blank Hindi name removes that translation', () {
      final edited = _onion.edited(
        names: {'en': 'Onion', 'hi': '  ', 'mr': ''},
        isActive: true,
      );

      expect(edited.translations.any((t) => t.language == 'hi'), isFalse);
      expect(edited.translations.any((t) => t.language == 'mr'), isFalse);
      expect(edited.nameIn('gu'), 'ડુંગળી');
    });
  });

  test('English is required and names have a length limit', () {
    expect(productNameProblems({'en': ' ', 'hi': 'x'}), {
      ProductNameProblem.englishMissing,
    });
    expect(productNameProblems({'en': 'a' * 121}), {
      ProductNameProblem.tooLong,
    });
    expect(productNameProblems({'en': 'Onion', 'hi': ''}), isEmpty);
  });

  test('the API answers are read', () {
    final summary = AdminProductsRepositoryImpl.parseSummary({
      'id': 'p1',
      'code': 'onion',
      'name': 'Onion',
      'categoryCode': 'veg',
      'subCategoryId': 'sc1',
      'subCategoryCode': 'roots',
      'defaultUnitCode': 'qtl',
      'displayOrder': 1,
      'isActive': false,
    });
    expect(summary.unitCode, 'qtl');
    expect(summary.isActive, isFalse);

    final product = AdminProductsRepositoryImpl.parseProduct({
      'id': 'p1',
      'code': 'onion',
      'subCategoryId': 'sc1',
      'defaultUnitId': 'u1',
      'displayOrder': 2,
      'isActive': true,
      'imageKey': null,
      'translations': [
        {'languageCode': 'en', 'name': 'Onion', 'description': null},
      ],
      'variants': [],
    });
    expect(product.nameIn('en'), 'Onion');
    expect(product.imageKey, isNull);
    expect(product.displayOrder, 2);
  });

  group('AdminProductsCubit', () {
    late _MockProducts repo;
    late _MockCommodities commodities;
    late AdminProductsCubit cubit;

    setUp(() {
      repo = _MockProducts();
      commodities = _MockCommodities();
      when(() => commodities.getTargets())
          .thenAnswer((_) async => const Ok(_targets));
      when(
        () => repo.createProduct(
          code: any(named: "code"),
          subCategoryId: any(named: "subCategoryId"),
          unitId: any(named: "unitId"),
          names: any(named: "names"),
        ),
      ).thenAnswer((_) async => const Ok(null));
      cubit = AdminProductsCubit(repo, commodities);
    });
    tearDown(() => cubit.close());

    Future<void> stubPage(int page, List<AdminProductSummary> rows) async =>
        when(
          () => repo.getProducts(
            page: page,
            pageSize: AdminProductsCubit.pageSize,
            search: any(named: 'search'),
          ),
        ).thenAnswer((_) async => Ok(rows));

    test('a full page means there may be more, and loadMore appends', () async {
      final first = [
        for (var i = 0; i < AdminProductsCubit.pageSize; i++)
          _summary('p$i', 'P$i'),
      ];
      await stubPage(1, first);
      await stubPage(2, [_summary('last', 'Last')]);

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();

      expect(cubit.state.products.length, first.length + 1);
      expect(cubit.state.hasMore, isFalse);
    });

    test('a search starts again from the first page', () async {
      await stubPage(1, [_summary('onion', 'Onion')]);

      await cubit.load(search: ' onion ');

      expect(cubit.state.search, 'onion');
      verify(
        () => repo.getProducts(
          page: 1,
          pageSize: AdminProductsCubit.pageSize,
          search: 'onion',
        ),
      ).called(1);
    });

    test('a failed first page is a failure', () async {
      when(
        () => repo.getProducts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });

    test('a save rereads the list; a refusal is returned', () async {
      await stubPage(1, [_summary('onion', 'Onion')]);
      when(() => repo.updateProduct(any()))
          .thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(await cubit.save(_onion), isNull);
      verify(() => repo.updateProduct(_onion)).called(1);
      verify(
        () => repo.getProducts(
          page: 1,
          pageSize: AdminProductsCubit.pageSize,
          search: '',
        ),
      ).called(2);

      when(() => repo.updateProduct(any()))
          .thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(await cubit.save(_onion), isA<ServerFailure>());
    });
  });

  group('AdminProductsPage', () {
    late _MockProducts repo;
    late _MockCommodities commodities;

    setUp(() {
      repo = _MockProducts();
      commodities = _MockCommodities();
      when(() => commodities.getTargets())
          .thenAnswer((_) async => const Ok(_targets));
      when(
        () => repo.createProduct(
          code: any(named: "code"),
          subCategoryId: any(named: "subCategoryId"),
          unitId: any(named: "unitId"),
          names: any(named: "names"),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.getProducts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _summary('onion', 'Onion'),
          _summary('tomato', 'Tomato', active: false),
        ]),
      );
      when(() => repo.getProduct('id-onion'))
          .thenAnswer((_) async => const Ok(_onion));
      when(() => repo.updateProduct(any()))
          .thenAnswer((_) async => const Ok(null));
    });

    Future<AdminProductsCubit> pump(WidgetTester tester) async {
      final cubit = AdminProductsCubit(repo, commodities);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminProductsPage()),
      );
      return cubit;
    }

    testWidgets('lists products and marks the switched-off ones', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Onion'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('submitting the search asks for that term', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'onion');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      verify(() => repo.getProducts(page: 1, pageSize: 30, search: 'onion'))
          .called(1);
    });

    testWidgets('edit the Marathi name and save', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Onion'));
      await tester.pumpAndSettle();
      expect(find.text('Edit product'), findsOneWidget);

      // The sheet's last field is the Marathi name.
      await tester.enterText(find.byType(TextField).last, 'कांदा');
      await tester.pump();
      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repo.updateProduct(captureAny())).captured.single
              as AdminProduct;
      expect(saved.nameIn('mr'), 'कांदा');
      expect(saved.nameIn('en'), 'Onion');
      expect(find.text('Edit product'), findsNothing);
    });

    Future<void> openNew(WidgetTester tester) async {
      await tester.tap(find.text('New product'));
      await tester.pumpAndSettle();
    }

    testWidgets('add a product by hand', (tester) async {
      await pump(tester);
      await openNew(tester);

      final fields = find.byType(TextField);
      // Search field, then code, English, Hindi, Marathi.
      await tester.enterText(fields.at(1), 'red-onion');
      await tester.enterText(fields.at(2), 'Red Onion');
      await tapVisible(tester, find.text('Choose a sub-category'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Vegetables › Roots'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Choose a unit'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Quintal (qtl)'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      verify(
        () => repo.createProduct(
          code: 'red-onion',
          subCategoryId: 'sc1',
          unitId: 'u1',
          names: {'en': 'Red Onion', 'hi': '', 'mr': ''},
        ),
      ).called(1);
      expect(find.text('New product'), findsOneWidget); // only the button
    });

    testWidgets('a new product needs everything before it is sent', (
      tester,
    ) async {
      await pump(tester);
      await openNew(tester);

      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the English name.'), findsOneWidget);
      expect(find.text('Choose a sub-category.'), findsOneWidget);
      expect(find.text('Choose a unit.'), findsOneWidget);
      verifyNever(
        () => repo.createProduct(
          code: any(named: 'code'),
          subCategoryId: any(named: 'subCategoryId'),
          unitId: any(named: 'unitId'),
          names: any(named: 'names'),
        ),
      );
    });

    testWidgets('a taken code is refused and the sheet stays open', (
      tester,
    ) async {
      when(
        () => repo.createProduct(
          code: any(named: 'code'),
          subCategoryId: any(named: 'subCategoryId'),
          unitId: any(named: 'unitId'),
          names: any(named: 'names'),
        ),
      ).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Code already used.')),
      );
      await pump(tester);
      await openNew(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'onion');
      await tester.enterText(fields.at(2), 'Onion');
      await tapVisible(tester, find.text('Choose a sub-category'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Vegetables › Roots'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Choose a unit'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Quintal (qtl)'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.text('Code already used.'), findsOneWidget);
      expect(find.text('Save product'), findsOneWidget);
    });

    Future<void> openVariants(WidgetTester tester) async {
      await tester.tap(find.text('Onion'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Variants (1)'));
      await tester.pumpAndSettle();
    }

    testWidgets('a product lists its variants', (tester) async {
      await pump(tester);
      await openVariants(tester);

      expect(find.textContaining('Large  ·  large'), findsOneWidget);
      expect(find.text('New variant'), findsOneWidget);
    });

    testWidgets('rename a variant; the list is reread', (tester) async {
      when(
        () => repo.updateVariant(
          productId: any(named: 'productId'),
          variant: any(named: 'variant'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await pump(tester);
      await openVariants(tester);

      await tester.tap(find.textContaining('Large  ·  large'));
      await tester.pumpAndSettle();
      expect(find.text('Edit variant'), findsOneWidget);
      // Fields: English, Hindi, Marathi.
      // The sheet on top owns the last three fields.
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 2), 'बड़ा');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(
                () => repo.updateVariant(
                  productId: 'id-onion',
                  variant: captureAny(named: 'variant'),
                ),
              ).captured.single
              as AdminVariant;
      expect(saved.nameIn('hi'), 'बड़ा');
      expect(saved.nameIn('en'), 'Large');
      // Once to open the product, once after the save.
      verify(() => repo.getProduct('id-onion')).called(greaterThanOrEqualTo(3));
    });

    testWidgets('add a variant', (tester) async {
      when(
        () => repo.addVariant(
          productId: any(named: 'productId'),
          code: any(named: 'code'),
          names: any(named: 'names'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await pump(tester);
      await openVariants(tester);

      await tester.tap(find.text('New variant'));
      await tester.pumpAndSettle();
      // Fields: code, English, Hindi, Marathi.
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 4), 'dry');
      await tester.enterText(find.byType(TextField).at(count - 3), 'Dry');
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.addVariant(
          productId: 'id-onion',
          code: 'dry',
          names: {'en': 'Dry', 'hi': '', 'mr': ''},
        ),
      ).called(1);
    });

    testWidgets('English cannot be cleared', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Onion'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Onion'), '');
      await tester.pump();
      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the English name.'), findsOneWidget);
      verifyNever(() => repo.updateProduct(any()));
    });

    testWidgets('a refused save stays open and says why', (tester) async {
      when(() => repo.updateProduct(any())).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Product is locked.')),
      );
      await pump(tester);

      await tester.tap(find.text('Onion'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save product'));
      await tester.pumpAndSettle();

      expect(find.text('Product is locked.'), findsOneWidget);
      expect(find.text('Edit product'), findsOneWidget);
    });
  });
}

/// Taps [finder] after scrolling it into view: the bottom sheets are taller
/// than the test window.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void _variantUnitTests() {
  test('variants are read from the product and edited by name', () {
    final product = AdminProductsRepositoryImpl.parseProduct({
      'id': 'p1',
      'code': 'onion',
      'subCategoryId': 'sc1',
      'defaultUnitId': 'u1',
      'displayOrder': 0,
      'isActive': true,
      'translations': [
        {'languageCode': 'en', 'name': 'Onion', 'description': null},
      ],
      'variants': [
        {
          'id': 'v1',
          'code': 'large',
          'displayOrder': 2,
          'isActive': false,
          'translations': [],
        },
      ],
    });

    final variant = product.variants.single;
    expect(variant.label, 'large'); // no name: the code
    expect(variant.isActive, isFalse);

    final edited = variant.edited(names: {'en': 'Large'}, isActive: true);
    expect(edited.label, 'Large');
    expect(edited.displayOrder, 2);
    expect(edited.code, 'large');
  });
}
