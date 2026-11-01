import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/presentation/admin_features_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_features_page.dart';
import 'package:mol_bhav/features/app_features/data/app_features_data.dart';
import 'package:mol_bhav/features/app_features/domain/app_features.dart';
import 'package:mol_bhav/features/app_features/presentation/feature_switches_cubit.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AppFeaturesRepository {}

const _reportsOff = {
  AppFeature.ads: true,
  AppFeature.reports: false,
  AppFeature.costEstimator: true,
};

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(AppFeature.ads));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.getAll())
        .thenAnswer((_) async => const Ok(_reportsOff));
    when(() => repository.set(any(), enabled: any(named: 'enabled')))
        .thenAnswer((_) async => const Ok(null));
  });

  group('parse', () {
    test('reads each known feature and ignores ones this build lacks', () {
      final flags = AppFeaturesRepositoryImpl.parse([
        {'feature': 'Reports', 'isEnabled': false},
        {'feature': 'FutureThing', 'isEnabled': false},
      ]);

      expect(flags[AppFeature.reports], isFalse);
      expect(flags.length, AppFeature.values.length);
    });

    test('a feature the server did not list is on', () {
      final flags = AppFeaturesRepositoryImpl.parse([]);

      expect(flags.values, everyElement(isTrue));
    });

    test('names match the API, ignoring case', () {
      expect(AppFeature.fromWire('costestimator'), AppFeature.costEstimator);
      expect(AppFeature.costEstimator.wire, 'CostEstimator');
      expect(AppFeature.fromWire('nope'), isNull);
    });
  });

  group('FeatureSwitchesCubit', () {
    late FeatureSwitchesCubit cubit;

    setUp(() => cubit = FeatureSwitchesCubit(repository));
    tearDown(() => cubit.close());

    test('everything is on until the server says otherwise', () {
      expect(cubit.state.isOn(AppFeature.ads), isTrue);
      expect(cubit.state.isOn(AppFeature.reports), isTrue);
    });

    test('loads what an admin switched off', () async {
      await cubit.load();

      expect(cubit.state.isOn(AppFeature.reports), isFalse);
      expect(cubit.state.isOn(AppFeature.ads), isTrue);
    });

    test('a failed check keeps what was last known', () async {
      await cubit.load();
      when(() => repository.getAll())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.isOn(AppFeature.reports), isFalse);
    });

    test('a change made here shows at once', () {
      cubit.apply(AppFeature.ads, enabled: false);

      expect(cubit.state.isOn(AppFeature.ads), isFalse);
    });
  });

  group('featureOn', () {
    Widget probe() => Builder(
      builder: (context) =>
          Text(context.featureOn(AppFeature.reports) ? 'on' : 'off'),
    );

    testWidgets('is on when nothing provides the switches', (tester) async {
      await tester.pumpApp(probe());

      expect(find.text('on'), findsOneWidget);
    });

    testWidgets('follows the cubit', (tester) async {
      final cubit = FeatureSwitchesCubit(repository);
      addTearDown(cubit.close);
      await tester.pumpApp(BlocProvider.value(value: cubit, child: probe()));
      expect(find.text('on'), findsOneWidget);

      await cubit.load();
      await tester.pump();

      expect(find.text('off'), findsOneWidget);
    });
  });

  group('AdminFeaturesCubit', () {
    late FeatureSwitchesCubit userFeatures;
    late AdminFeaturesCubit cubit;

    setUp(() {
      userFeatures = FeatureSwitchesCubit(repository);
      cubit = AdminFeaturesCubit(repository, userFeatures);
    });
    tearDown(() async {
      await cubit.close();
      await userFeatures.close();
    });

    test('a change is saved and shown to users at once', () async {
      await cubit.load();

      await cubit.setEnabled(AppFeature.ads, enabled: false);

      verify(() => repository.set(AppFeature.ads, enabled: false)).called(1);
      expect(cubit.state.flags.data![AppFeature.ads], isFalse);
      expect(cubit.state.saving, isEmpty);
      expect(userFeatures.state.isOn(AppFeature.ads), isFalse);
    });

    test('a refused change is put back and reported', () async {
      await cubit.load();
      when(() => repository.set(any(), enabled: any(named: 'enabled')))
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.setEnabled(AppFeature.reports, enabled: true);

      expect(cubit.state.flags.data![AppFeature.reports], isFalse);
      expect(cubit.state.saveFailure, isA<NetworkFailure>());
      expect(userFeatures.state.isOn(AppFeature.reports), isTrue);

      cubit.failureShown();
      expect(cubit.state.saveFailure, isNull);
    });

    test('nothing is changed before the list has loaded', () async {
      await cubit.setEnabled(AppFeature.ads, enabled: false);

      verifyNever(() => repository.set(any(), enabled: any(named: 'enabled')));
    });
  });

  group('AdminFeaturesPage', () {
    Future<void> pump(WidgetTester tester) async {
      final userFeatures = FeatureSwitchesCubit(repository);
      final cubit = AdminFeaturesCubit(repository, userFeatures);
      addTearDown(() async {
        await cubit.close();
        await userFeatures.close();
      });
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminFeaturesCubit>.value(
          value: cubit,
          child: const AdminFeaturesPage(),
        ),
      );
    }

    testWidgets('lists every feature with its state', (tester) async {
      await pump(tester);

      expect(find.text('Ads'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Cost estimator'), findsOneWidget);
      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .map((s) => s.value)
          .toList();
      expect(switches, [true, false, true]);
    });

    testWidgets('flipping a switch saves it', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      verify(() => repository.set(AppFeature.ads, enabled: false)).called(1);
    });

    testWidgets('a failed load shows an error', (tester) async {
      when(() => repository.getAll())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(LoadStatus.failure, isNotNull);
    });
  });
}
