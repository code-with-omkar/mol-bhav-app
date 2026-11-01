import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/features/price_status/domain/price_data_status.dart';
import 'package:mol_bhav/features/price_status/presentation/price_data_banner.dart';
import 'package:mol_bhav/features/price_status/presentation/price_data_status_cubit.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements PriceDataStatusRepository {}

void main() {
  late _MockRepository repository;
  late PriceDataStatusCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = PriceDataStatusCubit(repository);
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, PriceDataStatus status) async {
    when(() => repository.getStatus()).thenAnswer((_) async => Ok(status));
    await cubit.load();
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: const Scaffold(body: Column(children: [PriceDataBanner()])),
      ),
    );
  }

  testWidgets('says prices may be delayed and when they were last updated', (
    tester,
  ) async {
    await pump(
      tester,
      PriceDataStatus(
        isDelayed: true,
        lastUpdatedAt: DateTime(2026, 10, 15, 8),
      ),
    );

    expect(find.textContaining('Market prices may be delayed'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
  });

  testWidgets('says nothing about the update time when there never was one', (
    tester,
  ) async {
    await pump(tester, const PriceDataStatus(isDelayed: true));

    expect(find.textContaining('Market prices may be delayed'), findsOneWidget);
    expect(find.textContaining('Updated'), findsNothing);
  });

  testWidgets('is absent when prices are fresh', (tester) async {
    await pump(
      tester,
      PriceDataStatus(isDelayed: false, lastUpdatedAt: DateTime(2026, 10, 15)),
    );

    expect(find.textContaining('Market prices may be delayed'), findsNothing);
  });

  testWidgets('goes away when dismissed', (tester) async {
    await pump(tester, const PriceDataStatus(isDelayed: true));

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();

    expect(find.textContaining('Market prices may be delayed'), findsNothing);
  });
}
