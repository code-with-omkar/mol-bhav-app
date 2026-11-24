import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/suppliers/data/suppliers_data.dart';
import 'package:mol_bhav/features/suppliers/domain/suppliers.dart';
import 'package:mol_bhav/features/suppliers/presentation/suppliers_cubit.dart';
import 'package:mol_bhav/features/suppliers/presentation/suppliers_page.dart';

import '../../helpers/pump_app.dart';

class _MockSuppliers extends Mock implements SuppliersRepository {}

Supplier _supplier(String name, {String? phone}) => Supplier(
  id: 'id-$name',
  name: name,
  districtName: 'Rajkot',
  stateName: 'Gujarat',
  contactPhone: phone,
);

void main() {
  test('the API answer is read, phone optional', () {
    final s = SuppliersRepositoryImpl.parseSupplier({
      'id': 's1',
      'code': 'hub-1',
      'name': 'Hub One',
      'districtId': 'd1',
      'districtName': 'Rajkot',
      'stateName': 'Gujarat',
      'contactPhone': null,
    });

    expect(s.name, 'Hub One');
    expect(s.stateName, 'Gujarat');
    expect(s.contactPhone, isNull);
    expect(s.dialNumber, isNull);
  });

  test('the dial number keeps digits and a leading plus', () {
    expect(_supplier('A', phone: '+91 98765-43210').dialNumber, '+919876543210');
    expect(_supplier('A', phone: '').dialNumber, isNull);
    expect(_supplier('A', phone: 'n/a').dialNumber, isNull);
  });

  group('SuppliersCubit', () {
    late _MockSuppliers repo;
    late SuppliersCubit cubit;

    setUp(() {
      repo = _MockSuppliers();
      cubit = SuppliersCubit(repo);
    });
    tearDown(() => cubit.close());

    void stubPage(int page, List<Supplier> rows) => when(
      () => repo.getSuppliers(
        page: page,
        pageSize: SuppliersCubit.pageSize,
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => Ok(rows));

    test('a full page means there may be more, and loadMore appends', () async {
      final first = [
        for (var i = 0; i < SuppliersCubit.pageSize; i++) _supplier('S$i'),
      ];
      stubPage(1, first);
      stubPage(2, [_supplier('Last')]);

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
  });

  group('SuppliersPage', () {
    late _MockSuppliers repo;

    setUp(() {
      repo = _MockSuppliers();
      when(
        () => repo.getSuppliers(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
        ),
      ).thenAnswer(
        (_) async => Ok([
          _supplier('Hub One', phone: '+91 98765 43210'),
          _supplier('Hub Two'),
        ]),
      );
    });

    Future<void> pump(WidgetTester tester) async {
      final cubit = SuppliersCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const SuppliersPage()),
      );
    }

    testWidgets('lists suppliers; only one with a phone has Call', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Hub One'), findsOneWidget);
      expect(find.text('Hub Two'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
    });
  });
}
