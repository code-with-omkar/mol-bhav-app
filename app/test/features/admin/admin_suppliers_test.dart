import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_suppliers_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_mandis.dart';
import 'package:mol_bhav/features/admin/domain/admin_suppliers.dart';
import 'package:mol_bhav/features/admin/presentation/admin_suppliers_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_suppliers_page.dart';

import '../../helpers/pump_app.dart';

class _MockSuppliers extends Mock implements AdminSuppliersRepository {}

class _MockMandis extends Mock implements AdminMandisRepository {}

AdminSupplier _supplier(
  String code,
  String name, {
  bool active = true,
  String? phone,
}) => AdminSupplier(
  id: 'id-$code',
  code: code,
  name: name,
  districtId: 'd1',
  districtName: 'Rajkot',
  contactPhone: phone,
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
  test('the API answer is read, phone optional', () {
    final s = AdminSuppliersRepositoryImpl.parseSupplier({
      'id': 's1',
      'code': 'hub-1',
      'name': 'Hub One',
      'districtId': 'd1',
      'districtName': 'Rajkot',
      'contactPhone': null,
      'isActive': false,
    });

    expect(s.contactPhone, isNull);
    expect(s.isActive, isFalse);
    expect(s.districtName, 'Rajkot');
  });

  test('a phone is optional but must look like one', () {
    expect(isValidSupplierPhone('+91 98765-43210'), isTrue);
    expect(isValidSupplierPhone('9876543210'), isTrue);
    expect(isValidSupplierPhone('abc'), isFalse);
    expect(isValidSupplierPhone('12'), isFalse);
    expect(isValidSupplierPhone('1' * 21), isFalse);
    expect(
      supplierProblems(
        isNew: false,
        code: '',
        name: 'Hub',
        districtId: 'd1',
        phone: '',
      ),
      isEmpty,
    );
  });

  test('a new supplier needs a code, a name and a district', () {
    expect(
      supplierProblems(isNew: true, code: 'Bad', name: ' ', districtId: null),
      {
        SupplierProblem.codeInvalid,
        SupplierProblem.nameMissing,
        SupplierProblem.districtMissing,
      },
    );
  });

  group('AdminSuppliersCubit', () {
    late _MockSuppliers repo;
    late _MockMandis mandis;
    late AdminSuppliersCubit cubit;

    setUp(() {
      repo = _MockSuppliers();
      mandis = _MockMandis();
      cubit = AdminSuppliersCubit(repo, mandis);
    });
    tearDown(() => cubit.close());

    void stubPage(int page, List<AdminSupplier> rows) => when(
      () => repo.getSuppliers(
        page: page,
        pageSize: AdminSuppliersCubit.pageSize,
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Ok(rows));

    test('a full page means there may be more, and loadMore appends', () async {
      final first = [
        for (var i = 0; i < AdminSuppliersCubit.pageSize; i++)
          _supplier('s$i', 'S$i'),
      ];
      stubPage(1, first);
      stubPage(2, [_supplier('last', 'Last')]);

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();

      expect(cubit.state.suppliers.length, first.length + 1);
      expect(cubit.state.hasMore, isFalse);
    });

    test('a failed first page is a failure', () async {
      when(
        () => repo.getSuppliers(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });

    test('districts come from the mandis repository', () async {
      when(() => mandis.getDistricts())
          .thenAnswer((_) async => const Ok(_districts));

      final result = await cubit.districts();

      expect(result.fold((_) => null, (d) => d), _districts);
    });

    test('a save rereads the list; a refusal is returned', () async {
      stubPage(1, [_supplier('hub-1', 'Hub One')]);
      when(
        () => repo.createSupplier(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          contactPhone: any(named: 'contactPhone'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      await cubit.load();

      expect(
        await cubit.create(code: 'hub-2', name: 'Hub Two', districtId: 'd1'),
        isNull,
      );
      verify(
        () => repo.getSuppliers(
          page: 1,
          pageSize: AdminSuppliersCubit.pageSize,
          search: '',
        ),
      ).called(2);

      when(
        () => repo.updateSupplier(
          id: any(named: 'id'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          isActive: any(named: 'isActive'),
          contactPhone: any(named: 'contactPhone'),
        ),
      ).thenAnswer((_) async => const Err(ServerFailure(message: 'Nope.')));
      expect(
        await cubit.update(
          id: 'x',
          name: 'X',
          districtId: 'd1',
          isActive: true,
        ),
        isA<ServerFailure>(),
      );
    });
  });

  group('AdminSuppliersPage', () {
    late _MockSuppliers repo;
    late _MockMandis mandis;

    setUp(() {
      repo = _MockSuppliers();
      mandis = _MockMandis();
      when(
        () => repo.getSuppliers(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _supplier('hub-1', 'Hub One', phone: '+91 98765 43210'),
          _supplier('hub-2', 'Hub Two', active: false),
        ]),
      );
      when(() => mandis.getDistricts())
          .thenAnswer((_) async => const Ok(_districts));
      when(
        () => repo.updateSupplier(
          id: any(named: 'id'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          isActive: any(named: 'isActive'),
          contactPhone: any(named: 'contactPhone'),
        ),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => repo.createSupplier(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          contactPhone: any(named: 'contactPhone'),
        ),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = AdminSuppliersCubit(repo, mandis);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminSuppliersPage()),
      );
    }

    testWidgets('lists suppliers with phone and the Off badge', (tester) async {
      await pump(tester);

      expect(find.text('Hub One'), findsOneWidget);
      expect(find.textContaining('+91 98765 43210'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('edit a supplier: rename, clear the phone, switch it off', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Hub One'));
      await tester.pumpAndSettle();
      expect(find.text('Edit supplier'), findsOneWidget);
      expect(find.text('Code'), findsNothing);

      // Fields: search, name, phone.
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 2), 'Hub Prime');
      await tester.enterText(find.byType(TextField).at(count - 1), '');
      await tapVisible(tester, find.byType(Switch));
      await tester.pump();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.updateSupplier(
          id: 'id-hub-1',
          name: 'Hub Prime',
          districtId: 'd1',
          isActive: false,
          contactPhone: '',
        ),
      ).called(1);
    });

    testWidgets('add a supplier', (tester) async {
      await pump(tester);

      await tester.tap(find.text('New supplier'));
      await tester.pumpAndSettle();
      // Fields: code, name, phone (after the search field).
      final count = tester.widgetList(find.byType(TextField)).length;
      await tester.enterText(find.byType(TextField).at(count - 3), 'hub-3');
      await tester.enterText(find.byType(TextField).at(count - 2), 'Hub Three');
      await tapVisible(tester, find.text('Choose a district'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gujarat › Anand'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => repo.createSupplier(
          code: 'hub-3',
          name: 'Hub Three',
          districtId: 'd2',
          contactPhone: '',
        ),
      ).called(1);
    });

    testWidgets('a new supplier needs everything before it is sent', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('New supplier'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Choose a district.'), findsOneWidget);
      verifyNever(
        () => repo.createSupplier(
          code: any(named: 'code'),
          name: any(named: 'name'),
          districtId: any(named: 'districtId'),
          contactPhone: any(named: 'contactPhone'),
        ),
      );
    });
  });
}
