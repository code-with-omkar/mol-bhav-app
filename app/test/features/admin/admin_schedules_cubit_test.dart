import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/data_state.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/presentation/admin_schedules_cubit.dart';

class _MockRepository extends Mock implements AdminIngestionRepository {}

const _unscheduled = IngestionScheduleItem(
  sourceId: 's1',
  sourceCode: 'agmarknet',
  sourceName: 'Agmarknet',
  sourceIsActive: true,
  categoryCode: 'agriculture',
  categoryName: 'Agriculture',
  isConfigured: false,
  isEnabled: false,
);

const _daily = IngestionScheduleItem(
  sourceId: 's1',
  sourceCode: 'agmarknet',
  sourceName: 'Agmarknet',
  sourceIsActive: true,
  categoryCode: 'agriculture',
  categoryName: 'Agriculture',
  isConfigured: true,
  isEnabled: true,
  frequency: ScheduleFrequency.daily,
  timeOfDay: '18:00',
);

const _steel = IngestionScheduleItem(
  sourceId: 's2',
  sourceCode: 'steel-quotes',
  sourceName: 'Steel quotes',
  sourceIsActive: true,
  categoryCode: 'construction',
  categoryName: 'Construction',
  categoryDisplayOrder: 2,
  isConfigured: false,
  isEnabled: false,
);

const _agriculture = AdminCategory(code: 'agriculture', name: 'Agriculture');
const _construction = AdminCategory(code: 'construction', name: 'Construction');
const _interiors = AdminCategory(code: 'interiors', name: 'Interiors');

void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<int>[]);
    registerFallbackValue(
      const PriceSourceInput(code: 'x', name: 'x', categoryCode: 'x'),
    );
    registerFallbackValue(
      const ScheduleInput(
        isEnabled: true,
        frequency: ScheduleFrequency.daily,
        timeOfDay: '18:00',
        dayOfWeek: 'Monday',
        intervalHours: 6,
      ),
    );
  });

  setUp(() => repository = _MockRepository());

  group('ScheduleInput.toJson', () {
    test('sends only the fields the frequency uses', () {
      const base = ScheduleInput(
        isEnabled: true,
        frequency: ScheduleFrequency.daily,
        timeOfDay: '06:30',
        dayOfWeek: 'Friday',
        intervalHours: 4,
      );

      expect(base.toJson(), {
        'isEnabled': true,
        'frequency': 'Daily',
        'timeOfDay': '06:30',
      });
      expect(
        base.copyWith(frequency: ScheduleFrequency.weekly).toJson(),
        containsPair('dayOfWeek', 'Friday'),
      );
      expect(
        base.copyWith(frequency: ScheduleFrequency.everyNHours).toJson(),
        containsPair('intervalHours', 4),
      );
    });

    test(
      'an unscheduled source opens the editor as enabled daily at 18:00',
      () {
        final input = _unscheduled.toInput();

        expect(input.isEnabled, isTrue);
        expect(input.frequency, ScheduleFrequency.daily);
        expect(input.timeOfDay, '18:00');
      },
    );
  });

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'load emits loading then the schedules and categories',
    setUp: () {
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Ok([_unscheduled]));
      when(() => repository.getCategories())
          .thenAnswer((_) async => const Ok([_agriculture, _construction]));
    },
    build: () => AdminSchedulesCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => const [
      AdminSchedulesState(items: DataState.loading()),
      AdminSchedulesState(
        items: DataState.ready([_unscheduled]),
        categories: [_agriculture, _construction],
      ),
    ],
  );

  group('sections', () {
    const state = AdminSchedulesState(
      items: DataState.ready([_steel, _daily]),
      categories: [_agriculture, _construction, _interiors],
    );

    test('group sources by category, keeping categories with no source', () {
      final sections = state.sections;

      expect(sections.map((s) => s.$1.code), [
        'agriculture',
        'construction',
        'interiors',
      ]);
      expect(sections[0].$2, [_daily]);
      expect(sections[1].$2, [_steel]);
      expect(sections[2].$2, isEmpty);
    });

    test('the filter keeps only the selected category', () {
      final filtered = state.copyWith(selectedCategory: () => 'construction');

      expect(filtered.sections.single.$2, [_steel]);
      expect(
        filtered.copyWith(selectedCategory: () => null).sections,
        hasLength(3),
      );
    });

    test('falls back to categories found on sources when the list failed', () {
      const noList = AdminSchedulesState(
        items: DataState.ready([_steel, _daily]),
      );

      expect(noList.visibleCategories.map((c) => c.code), [
        'agriculture',
        'construction',
      ]);
    });
  });

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'runCategory reports how many sources were queued without reloading',
    setUp: () =>
        when(() => repository.runCategory(any()))
            .thenAnswer((_) async => const Ok(3)),
    build: () => AdminSchedulesCubit(repository),
    seed: () => const AdminSchedulesState(items: DataState.ready([_steel])),
    act: (cubit) => cubit.runCategory('construction'),
    expect: () => const [
      AdminSchedulesState(
        items: DataState.ready([_steel]),
        busyCategories: {'construction'},
      ),
      AdminSchedulesState(
        items: DataState.ready([_steel]),
        lastAction: AdminActionKind.categoryRunQueued,
        queuedSources: 3,
        actionSeq: 1,
      ),
    ],
    verify: (_) => verifyNever(() => repository.getSchedules()),
  );

  test(
    'createSource reloads on success and reports false on failure',
    () async {
      const input = PriceSourceInput(
        code: 'steel-quotes',
        name: 'Steel quotes',
        categoryCode: 'construction',
      );
      when(() => repository.createSource(input))
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Ok([_daily, _steel]));
      final cubit = AdminSchedulesCubit(repository);

      expect(await cubit.createSource(input), isTrue);
      expect(cubit.state.items.data, [_daily, _steel]);
      expect(cubit.state.lastAction, AdminActionKind.sourceCreated);

      when(() => repository.createSource(any()))
          .thenAnswer((_) async => const Err(ServerFailure(statusCode: 409)));
      expect(await cubit.createSource(input), isFalse);
      expect(cubit.state.actionFailure, const ServerFailure(statusCode: 409));
      await cubit.close();
    },
  );

  test('PriceSourceInput sends the category on create and update', () {
    const input = PriceSourceInput(
      code: ' CPWD-DSR ',
      name: ' CPWD DSR ',
      categoryCode: 'construction',
      isActive: false,
    );

    expect(input.toCreateJson(), {
      'code': 'cpwd-dsr',
      'name': 'CPWD DSR',
      'categoryCode': 'construction',
    });
    expect(input.toUpdateJson(), {
      'name': 'CPWD DSR',
      'isActive': false,
      'categoryCode': 'construction',
    });
    expect(PriceSourceInput.codePattern.hasMatch('cpwd-dsr'), isTrue);
    expect(PriceSourceInput.codePattern.hasMatch('CPWD DSR'), isFalse);
  });

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'save calls the API, reloads and reports success',
    setUp: () {
      when(() => repository.saveSchedule(any(), any()))
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Ok([_daily]));
    },
    build: () => AdminSchedulesCubit(repository),
    seed: () =>
        const AdminSchedulesState(items: DataState.ready([_unscheduled])),
    act: (cubit) => cubit.save('s1', _unscheduled.toInput()),
    expect: () => const [
      AdminSchedulesState(
        items: DataState.ready([_unscheduled]),
        busySourceIds: {'s1'},
      ),
      AdminSchedulesState(
        items: DataState.ready([_daily]),
        lastAction: AdminActionKind.saved,
        actionSeq: 1,
      ),
    ],
    verify: (_) => verify(() => repository.saveSchedule('s1', any())).called(1),
  );

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'a failed run keeps the list and surfaces the failure',
    setUp: () {
      when(() => repository.runNow(any()))
          .thenAnswer((_) async => const Err(ServerFailure(statusCode: 403)));
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: () => AdminSchedulesCubit(repository),
    seed: () => const AdminSchedulesState(items: DataState.ready([_daily])),
    act: (cubit) => cubit.runNow('s1'),
    skip: 1,
    expect: () => const [
      AdminSchedulesState(
        items: DataState(
          status: LoadStatus.failure,
          data: [_daily],
          failure: NetworkFailure(),
        ),
        actionFailure: ServerFailure(statusCode: 403),
        actionSeq: 1,
      ),
    ],
  );

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'ignores a second action on a source that is already busy',
    build: () => AdminSchedulesCubit(repository),
    seed: () => const AdminSchedulesState(
      items: DataState.ready([_daily]),
      busySourceIds: {'s1'},
    ),
    act: (cubit) => cubit.runNow('s1'),
    expect: () => const <AdminSchedulesState>[],
    verify: (_) => verifyNever(() => repository.runNow(any())),
  );

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'backfill reports how many days were queued without reloading',
    setUp: () =>
        when(() => repository.backfill(any(), any(), any()))
            .thenAnswer((_) async => const Ok(7)),
    build: () => AdminSchedulesCubit(repository),
    seed: () => const AdminSchedulesState(items: DataState.ready([_daily])),
    act: (cubit) =>
        cubit.backfill('s1', DateTime(2026, 9, 27), DateTime(2026, 10, 3)),
    expect: () => const [
      AdminSchedulesState(
        items: DataState.ready([_daily]),
        busySourceIds: {'s1'},
      ),
      AdminSchedulesState(
        items: DataState.ready([_daily]),
        lastAction: AdminActionKind.backfillQueued,
        queuedDays: 7,
        actionSeq: 1,
      ),
    ],
    verify: (_) => verifyNever(() => repository.getSchedules()),
  );

  blocTest<AdminSchedulesCubit, AdminSchedulesState>(
    'uploadCsv sends the file, reloads and reports success',
    setUp: () {
      when(() => repository.uploadCsv(any(), any(), any()))
          .thenAnswer((_) async => const Ok(null));
      when(() => repository.getSchedules())
          .thenAnswer((_) async => const Ok([_daily]));
    },
    build: () => AdminSchedulesCubit(repository),
    seed: () => const AdminSchedulesState(items: DataState.ready([_daily])),
    act: (cubit) => cubit.uploadCsv('s1', 'prices.csv', [1, 2, 3]),
    skip: 1,
    expect: () => const [
      AdminSchedulesState(
        items: DataState.ready([_daily]),
        lastAction: AdminActionKind.uploaded,
        actionSeq: 1,
      ),
    ],
    verify: (_) =>
        verify(() => repository.uploadCsv('s1', 'prices.csv', any())).called(1),
  );
}
