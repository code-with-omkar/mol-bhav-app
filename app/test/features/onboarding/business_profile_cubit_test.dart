import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/locale/app_language.dart';
import 'package:mol_bhav/core/locale/locale_repository.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:mol_bhav/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:mol_bhav/features/onboarding/presentation/cubit/business_profile_cubit.dart';

class _MockGetProfileOptions extends Mock implements GetProfileOptions {}

class _MockGetDistricts extends Mock implements GetDistricts {}

class _MockSaveBusinessProfile extends Mock implements SaveBusinessProfile {}

class _MockLocaleRepository extends Mock implements LocaleRepository {}

void main() {
  late _MockGetProfileOptions getOptions;
  late _MockGetDistricts getDistricts;
  late _MockSaveBusinessProfile save;
  late _MockLocaleRepository locale;

  const options = ProfileOptions(
    businessTypes: [BusinessType(id: 't1', name: 'Type 1')],
    states: [Region(code: 's1', name: 'State 1')],
  );
  const districts = [Region(code: 'd1', name: 'District 1')];

  setUpAll(() {
    registerFallbackValue(
      const BusinessProfile(
        businessTypeId: '',
        stateCode: '',
        districtCode: '',
        preferredLanguage: '',
      ),
    );
  });

  setUp(() {
    getOptions = _MockGetProfileOptions();
    getDistricts = _MockGetDistricts();
    save = _MockSaveBusinessProfile();
    locale = _MockLocaleRepository();
    when(() => locale.current).thenReturn(AppLanguage.marathi);
  });

  BusinessProfileCubit build() =>
      BusinessProfileCubit(getOptions, getDistricts, save, locale);

  test('defaults the preferred language to the app language', () {
    expect(build().state.language, AppLanguage.marathi);
  });

  blocTest<BusinessProfileCubit, BusinessProfileState>(
    'load emits ready with options',
    setUp: () =>
        when(() => getOptions()).thenAnswer((_) async => const Ok(options)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => const [
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.loading,
      ),
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.ready,
        options: options,
      ),
    ],
  );

  blocTest<BusinessProfileCubit, BusinessProfileState>(
    'load emits failure, and retry recovers',
    setUp: () {
      var calls = 0;
      when(() => getOptions()).thenAnswer(
        (_) async =>
            calls++ == 0 ? const Err(NetworkFailure()) : const Ok(options),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => const [
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.loading,
      ),
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.failure,
        optionsFailure: NetworkFailure(),
      ),
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.loading,
        optionsFailure: NetworkFailure(),
      ),
      BusinessProfileState(
        language: AppLanguage.marathi,
        optionsStatus: LoadStatus.ready,
        options: options,
      ),
    ],
  );

  blocTest<BusinessProfileCubit, BusinessProfileState>(
    'selecting a state clears the district and loads districts',
    setUp: () =>
        when(() => getDistricts(any()))
            .thenAnswer((_) async => const Ok(districts)),
    build: build,
    seed: () => const BusinessProfileState(
      language: AppLanguage.marathi,
      stateCode: 'old',
      districtCode: 'old-d',
    ),
    act: (cubit) => cubit.selectState('s1'),
    expect: () => const [
      BusinessProfileState(language: AppLanguage.marathi, stateCode: 's1'),
      BusinessProfileState(
        language: AppLanguage.marathi,
        stateCode: 's1',
        districtsStatus: LoadStatus.loading,
      ),
      BusinessProfileState(
        language: AppLanguage.marathi,
        stateCode: 's1',
        districtsStatus: LoadStatus.ready,
        districts: districts,
      ),
    ],
  );

  blocTest<BusinessProfileCubit, BusinessProfileState>(
    'district load failure is shown on the field',
    setUp: () =>
        when(() => getDistricts(any()))
            .thenAnswer((_) async => const Err(NetworkFailure())),
    build: build,
    act: (cubit) => cubit.selectState('s1'),
    skip: 2,
    expect: () => const [
      BusinessProfileState(
        language: AppLanguage.marathi,
        stateCode: 's1',
        districtsStatus: LoadStatus.failure,
      ),
    ],
  );

  test('canSubmit needs business type, state and district', () {
    const base = BusinessProfileState(language: AppLanguage.english);
    expect(base.canSubmit, isFalse);
    expect(
      const BusinessProfileState(
        language: AppLanguage.english,
        businessTypeId: 't1',
        stateCode: 's1',
        districtCode: 'd1',
      ).canSubmit,
      isTrue,
    );
  });

  blocTest<BusinessProfileCubit, BusinessProfileState>(
    'submit saves the profile with the chosen language',
    setUp: () =>
        when(() => save(any())).thenAnswer((_) async => const Ok(null)),
    build: build,
    seed: () => const BusinessProfileState(
      language: AppLanguage.hindi,
      businessTypeId: 't1',
      stateCode: 's1',
      districtCode: 'd1',
    ),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      BusinessProfileState(
        language: AppLanguage.hindi,
        businessTypeId: 't1',
        stateCode: 's1',
        districtCode: 'd1',
        submitStatus: SubmitStatus.submitting,
      ),
      BusinessProfileState(
        language: AppLanguage.hindi,
        businessTypeId: 't1',
        stateCode: 's1',
        districtCode: 'd1',
        submitStatus: SubmitStatus.success,
      ),
    ],
    verify: (_) => verify(
      () => save(
        const BusinessProfile(
          businessTypeId: 't1',
          stateCode: 's1',
          districtCode: 'd1',
          preferredLanguage: 'hi',
        ),
      ),
    ).called(1),
  );
}
