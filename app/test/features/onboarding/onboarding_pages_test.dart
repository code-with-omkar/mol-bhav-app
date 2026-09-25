import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/locale/app_language.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:mol_bhav/features/onboarding/presentation/cubit/business_profile_cubit.dart';
import 'package:mol_bhav/features/onboarding/presentation/cubit/select_category_cubit.dart';
import 'package:mol_bhav/features/onboarding/presentation/pages/business_profile_page.dart';
import 'package:mol_bhav/features/onboarding/presentation/pages/select_category_page.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockProfileCubit extends MockCubit<BusinessProfileState>
    implements BusinessProfileCubit {}

class _MockCategoryCubit extends MockCubit<SelectCategoryState>
    implements SelectCategoryCubit {}

const _categories = [
  ProcurementCategory(
    id: '1',
    code: 'agriculture',
    name: 'Agri',
    highlights: ['H1', 'H2'],
    isAvailable: true,
  ),
  ProcurementCategory(
    id: '2',
    code: 'pharma',
    name: 'Pharm',
    highlights: [],
    isAvailable: false,
  ),
];

void main() {
  group('BusinessProfilePage', () {
    late _MockProfileCubit cubit;

    setUp(() => cubit = _MockProfileCubit());

    Future<void> pump(WidgetTester tester, BusinessProfileState state) {
      when(() => cubit.state).thenReturn(state);
      return tester.pumpApp(
        BlocProvider<BusinessProfileCubit>.value(
          value: cubit,
          child: const BusinessProfilePage(),
        ),
      );
    }

    testWidgets('shows a loader while options load', (tester) async {
      await pump(
        tester,
        const BusinessProfileState(
          language: AppLanguage.english,
          optionsStatus: LoadStatus.loading,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('shows an error with retry', (tester) async {
      when(() => cubit.load()).thenAnswer((_) async {});
      await pump(
        tester,
        const BusinessProfileState(
          language: AppLanguage.english,
          optionsStatus: LoadStatus.failure,
          optionsFailure: NetworkFailure(),
        ),
      );

      await tester.tap(find.text('Retry'));

      verify(() => cubit.load()).called(1);
    });

    testWidgets('renders the form from API options', (tester) async {
      when(() => cubit.selectBusinessType(any())).thenReturn(null);
      await pump(
        tester,
        const BusinessProfileState(
          language: AppLanguage.english,
          optionsStatus: LoadStatus.ready,
          options: ProfileOptions(
            businessTypes: [BusinessType(id: 't1', name: 'Type One')],
            states: [Region(code: 's1', name: 'State One')],
          ),
        ),
      );

      expect(find.text('Your business'), findsOneWidget);
      expect(find.text('Business type'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('Select a state first'), findsOneWidget);
      expect(find.text('Preferred language'), findsOneWidget);
      final cta = tester.widget<MbButton>(
        find.widgetWithText(MbButton, 'Continue'),
      );
      expect(cta.onPressed, isNull);

      await tester.tap(find.text('Type One'));
      verify(() => cubit.selectBusinessType('t1')).called(1);
    });
  });

  group('SelectCategoryPage', () {
    late _MockCategoryCubit cubit;

    setUp(() => cubit = _MockCategoryCubit());

    Future<void> pump(WidgetTester tester, SelectCategoryState state) {
      when(() => cubit.state).thenReturn(state);
      return tester.pumpApp(
        BlocProvider<SelectCategoryCubit>.value(
          value: cubit,
          child: const SelectCategoryPage(),
        ),
      );
    }

    testWidgets('lists categories with coming-soon and a counter', (
      tester,
    ) async {
      when(() => cubit.toggle(any())).thenReturn(null);
      await pump(
        tester,
        const SelectCategoryState(
          status: LoadStatus.ready,
          categories: _categories,
          selected: {'1'},
        ),
      );

      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Agri'), findsOneWidget);
      expect(find.text('H1 · H2'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Continue (1 selected)'), findsOneWidget);

      await tester.tap(find.text('Pharm'));
      verifyNever(() => cubit.toggle('2'));
      await tester.tap(find.text('Agri'));
      verify(() => cubit.toggle('1')).called(1);
    });

    testWidgets('shows the empty state', (tester) async {
      await pump(tester, const SelectCategoryState(status: LoadStatus.ready));

      expect(
        find.text('No categories are available right now.'),
        findsOneWidget,
      );
      expect(find.byType(MbButton), findsOneWidget); // Retry only.
    });

    testWidgets('shows an error with retry', (tester) async {
      when(() => cubit.load()).thenAnswer((_) async {});
      await pump(
        tester,
        const SelectCategoryState(
          status: LoadStatus.failure,
          failure: ServerFailure(),
        ),
      );

      expect(
        find.text('Something went wrong on our side. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      verify(() => cubit.load()).called(1);
    });
  });
}
