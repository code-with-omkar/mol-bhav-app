import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/session/session_manager.dart';
import 'package:mol_bhav/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:mol_bhav/features/onboarding/data/models/onboarding_models.dart';
import 'package:mol_bhav/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:mol_bhav/features/onboarding/domain/entities/onboarding_entities.dart';

class _MockRemote extends Mock implements OnboardingRemoteDataSource {}

class _MockSession extends Mock implements SessionManager {}

void main() {
  late _MockRemote remote;
  late OnboardingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const BusinessProfileRequest(
        BusinessProfile(
          displayName: '',
          businessTypeId: '',
          stateCode: '',
          districtCode: '',
          preferredLanguage: '',
        ),
      ),
    );
  });

  setUp(() {
    remote = _MockRemote();
    repository = OnboardingRepositoryImpl(remote, _MockSession());
  });

  test('getProfileOptions combines business types and states', () async {
    when(() => remote.getBusinessTypes()).thenAnswer(
      (_) async => [const BusinessTypeModel(id: 't1', name: 'Type 1')],
    );
    when(
      () => remote.getStates(),
    ).thenAnswer((_) async => [const RegionModel(code: 's1', name: 'State 1')]);

    final result = await repository.getProfileOptions();

    expect(
      result.fold((_) => null, (o) => o),
      const ProfileOptions(
        businessTypes: [BusinessType(id: 't1', name: 'Type 1')],
        states: [Region(code: 's1', name: 'State 1')],
      ),
    );
  });

  test('getProfileOptions maps a failing call to a Failure', () async {
    when(() => remote.getBusinessTypes()).thenAnswer((_) async => []);
    when(() => remote.getStates()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/reference/states'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.getProfileOptions();

    expect(result.fold((f) => f, (_) => null), const NetworkFailure());
  });

  test('saveBusinessProfile sends the documented body', () async {
    when(() => remote.saveBusinessProfile(any())).thenAnswer((_) async {});
    const profile = BusinessProfile(
      displayName: 'Ramesh Patil',
      businessTypeId: 't1',
      stateCode: 's1',
      districtCode: 'd1',
      preferredLanguage: 'mr',
    );

    await repository.saveBusinessProfile(profile);

    final sent =
        verify(() => remote.saveBusinessProfile(captureAny())).captured.single
            as BusinessProfileRequest;
    expect(sent.toJson(), {
      'displayName': 'Ramesh Patil',
      'businessType': 't1',
      'state': 's1',
      'district': 'd1',
      'preferredLanguage': 'mr',
      'categories': <String>[],
    });
  });

  test('saveCategories sends the ids', () async {
    final session = _MockSession();
    when(session.completeOnboarding).thenAnswer((_) async {});
    repository = OnboardingRepositoryImpl(remote, session);
    when(() => remote.saveCategories(any())).thenAnswer((_) async {});

    await repository.saveCategories({'1', '2'});

    verify(() => remote.saveCategories(['1', '2'])).called(1);
    verify(session.completeOnboarding).called(1);
  });

  test('CategoryModel keys the category by its code and carries no highlights', () {
    // The API identifies categories by `code`; it sends no highlights or flags.
    final model = CategoryModel.fromJson({
      'code': 'agriculture',
      'name': 'Agriculture',
    });

    expect(
      model.toEntity(),
      const ProcurementCategory(
        id: 'agriculture',
        code: 'agriculture',
        name: 'Agriculture',
        highlights: [],
        isAvailable: true,
      ),
    );
  });

  test('CategoryModel tolerates missing highlights', () {
    final model = CategoryModel.fromJson({
      'id': '9',
      'code': 'pharma',
      'name': 'Pharma',
      'isAvailable': false,
    });

    expect(model.highlights, isEmpty);
  });
}
