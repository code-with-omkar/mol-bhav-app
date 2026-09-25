import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:mol_bhav/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:mol_bhav/features/onboarding/presentation/cubit/select_category_cubit.dart';

class _MockGetCategories extends Mock implements GetCategories {}

class _MockSaveCategories extends Mock implements SaveCategories {}

const _available = ProcurementCategory(
  id: '1',
  code: 'agriculture',
  name: 'A',
  highlights: [],
  isAvailable: true,
);
const _comingSoon = ProcurementCategory(
  id: '2',
  code: 'pharma',
  name: 'P',
  highlights: [],
  isAvailable: false,
);
const _categories = [_available, _comingSoon];

void main() {
  late _MockGetCategories getCategories;
  late _MockSaveCategories saveCategories;

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    getCategories = _MockGetCategories();
    saveCategories = _MockSaveCategories();
  });

  SelectCategoryCubit build() =>
      SelectCategoryCubit(getCategories, saveCategories);

  blocTest<SelectCategoryCubit, SelectCategoryState>(
    'load emits ready with categories',
    setUp: () =>
        when(() => getCategories())
            .thenAnswer((_) async => const Ok(_categories)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => const [
      SelectCategoryState(status: LoadStatus.loading),
      SelectCategoryState(status: LoadStatus.ready, categories: _categories),
    ],
  );

  blocTest<SelectCategoryCubit, SelectCategoryState>(
    'load emits failure',
    setUp: () =>
        when(() => getCategories())
            .thenAnswer((_) async => const Err(ServerFailure(statusCode: 500))),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => const [
      SelectCategoryState(status: LoadStatus.loading),
      SelectCategoryState(
        status: LoadStatus.failure,
        failure: ServerFailure(statusCode: 500),
      ),
    ],
  );

  blocTest<SelectCategoryCubit, SelectCategoryState>(
    'toggles available categories and ignores coming-soon ones',
    build: build,
    seed: () => const SelectCategoryState(
      status: LoadStatus.ready,
      categories: _categories,
    ),
    act: (cubit) => cubit
      ..toggle('2')
      ..toggle('1')
      ..toggle('1'),
    expect: () => const [
      SelectCategoryState(
        status: LoadStatus.ready,
        categories: _categories,
        selected: {'1'},
      ),
      SelectCategoryState(status: LoadStatus.ready, categories: _categories),
    ],
  );

  blocTest<SelectCategoryCubit, SelectCategoryState>(
    'submit is ignored with nothing selected',
    build: build,
    seed: () => const SelectCategoryState(
      status: LoadStatus.ready,
      categories: _categories,
    ),
    act: (cubit) => cubit.submit(),
    expect: () => const <SelectCategoryState>[],
    verify: (_) => verifyNever(() => saveCategories(any())),
  );

  blocTest<SelectCategoryCubit, SelectCategoryState>(
    'submit saves the selection',
    setUp: () =>
        when(() => saveCategories(any()))
            .thenAnswer((_) async => const Ok(null)),
    build: build,
    seed: () => const SelectCategoryState(
      status: LoadStatus.ready,
      categories: _categories,
      selected: {'1'},
    ),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      SelectCategoryState(
        status: LoadStatus.ready,
        categories: _categories,
        selected: {'1'},
        submitStatus: SubmitStatus.submitting,
      ),
      SelectCategoryState(
        status: LoadStatus.ready,
        categories: _categories,
        selected: {'1'},
        submitStatus: SubmitStatus.success,
      ),
    ],
    verify: (_) => verify(() => saveCategories({'1'})).called(1),
  );
}
