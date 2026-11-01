import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/presentation/admin_notice_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_notice_page.dart';
import 'package:mol_bhav/features/app_notice/data/app_notice_data.dart';
import 'package:mol_bhav/features/app_notice/domain/app_notice.dart';
import 'package:mol_bhav/features/app_notice/presentation/app_notice_banner.dart';
import 'package:mol_bhav/features/app_notice/presentation/app_notice_cubit.dart';
import 'package:mol_bhav/features/app_notice/presentation/maintenance_view.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockRepository extends Mock implements AppNoticeRepository {}

const _info = AppNotice(
  isActive: true,
  severity: NoticeSeverity.info,
  message: 'New prices tonight.',
);

const _maintenance = AppNotice(
  isActive: true,
  severity: NoticeSeverity.maintenance,
  message: 'Back at 6 pm.',
);

const _off = AppNotice(
  isActive: false,
  severity: NoticeSeverity.warning,
  message: 'Old news',
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(_info));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.get()).thenAnswer((_) async => const Ok(_info));
    when(() => repository.getForEditing())
        .thenAnswer((_) async => const Ok(_off));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  group('AppNotice', () {
    test('reads the API answer, unknown types as the mildest', () {
      final notice = AppNoticeRepositoryImpl.parse({
        'isActive': true,
        'severity': 'Maintenance',
        'message': 'Back at 6 pm.',
      });
      expect(notice, _maintenance);
      expect(NoticeSeverity.fromWire('Something'), NoticeSeverity.info);
      expect(NoticeSeverity.maintenance.wire, 'Maintenance');
    });

    test('only an on notice with text is visible; only maintenance blocks', () {
      expect(_info.isVisible, isTrue);
      expect(_info.blocksApp, isFalse);
      expect(_maintenance.blocksApp, isTrue);
      expect(_off.isVisible, isFalse);
      expect(
        const AppNotice(
          isActive: true,
          severity: NoticeSeverity.info,
          message: '   ',
        ).isVisible,
        isFalse,
      );
      expect(const AppNotice.off().isVisible, isFalse);
    });
  });

  group('AppNoticeCubit', () {
    late AppNoticeCubit cubit;

    setUp(() => cubit = AppNoticeCubit(repository));
    tearDown(() => cubit.close());

    test(
      'shows a note as a banner and a maintenance notice as a page',
      () async {
        await cubit.load();
        expect(cubit.state.showBanner, isTrue);
        expect(cubit.state.blocking, isFalse);

        when(() => repository.get())
            .thenAnswer((_) async => const Ok(_maintenance));
        await cubit.load();
        expect(cubit.state.showBanner, isFalse);
        expect(cubit.state.blocking, isTrue);
      },
    );

    test('closing the banner holds for the same message only', () async {
      await cubit.load();
      cubit.dismiss();
      expect(cubit.state.showBanner, isFalse);

      await cubit.load(); // same message again
      expect(cubit.state.showBanner, isFalse);

      when(() => repository.get()).thenAnswer(
        (_) async => const Ok(
          AppNotice(
            isActive: true,
            severity: NoticeSeverity.info,
            message: 'Something else.',
          ),
        ),
      );
      await cubit.load();
      expect(cubit.state.showBanner, isTrue);
    });

    test('a failed check keeps what was last known', () async {
      await cubit.load();
      when(() => repository.get())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.notice, _info);
    });

    test('switching it off clears the banner', () async {
      await cubit.load();
      when(() => repository.get())
          .thenAnswer((_) async => const Ok(AppNotice.off()));

      await cubit.load();

      expect(cubit.state.showBanner, isFalse);
      expect(cubit.state.blocking, isFalse);
    });
  });

  group('AdminNoticeCubit', () {
    late AppNoticeCubit userNotice;
    late AdminNoticeCubit cubit;

    setUp(() {
      userNotice = AppNoticeCubit(repository);
      cubit = AdminNoticeCubit(repository, userNotice);
    });
    tearDown(() async {
      await cubit.close();
      await userNotice.close();
    });

    test('loads the notice as saved, even one switched off', () async {
      await cubit.load();

      expect(cubit.state.notice.data, _off);
    });

    test('a save refreshes what users see', () async {
      await cubit.save(_maintenance);

      verify(() => repository.save(_maintenance)).called(1);
      expect(cubit.state.saves, 1);
      expect(cubit.state.notice.data, _maintenance);
      verify(() => repository.get()).called(1);
    });

    test(
      'a failed save is kept to be shown, and nothing is refreshed',
      () async {
        when(() => repository.save(any()))
            .thenAnswer((_) async => const Err(NetworkFailure()));

        await cubit.save(_maintenance);

        expect(cubit.state.saves, 0);
        expect(cubit.state.saveFailure, isA<NetworkFailure>());
        verifyNever(() => repository.get());

        cubit.failureShown();
        expect(cubit.state.saveFailure, isNull);
      },
    );
  });

  group('AppNoticeBanner', () {
    testWidgets('shows the message and closes on tap', (tester) async {
      final cubit = AppNoticeCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AppNoticeBanner()),
      );
      expect(find.text('New prices tonight.'), findsOneWidget);

      await tester.tap(find.byTooltip('Close message'));
      await tester.pump();

      expect(find.text('New prices tonight.'), findsNothing);
    });

    testWidgets('shows nothing when there is no notice', (tester) async {
      final cubit = AppNoticeCubit(repository);
      addTearDown(cubit.close);
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AppNoticeBanner()),
      );

      expect(find.byType(Text), findsNothing);
    });
  });

  group('MaintenanceView', () {
    testWidgets('shows the message and checks again on tap', (tester) async {
      when(() => repository.get())
          .thenAnswer((_) async => const Ok(_maintenance));
      final cubit = AppNoticeCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const MaintenanceView()),
      );
      expect(find.text('We will be back soon'), findsOneWidget);
      expect(find.text('Back at 6 pm.'), findsOneWidget);

      await tester.tap(find.text('Check again'));
      await tester.pump();

      verify(() => repository.get()).called(2); // the first load and this one
    });
  });

  group('AdminNoticePage', () {
    Future<AdminNoticeCubit> pump(WidgetTester tester) async {
      final userNotice = AppNoticeCubit(repository);
      final cubit = AdminNoticeCubit(repository, userNotice);
      addTearDown(() async {
        await cubit.close();
        await userNotice.close();
      });
      await cubit.load();
      await tester.pumpApp(
        BlocProvider<AdminNoticeCubit>.value(
          value: cubit,
          child: const AdminNoticePage(),
        ),
      );
      return cubit;
    }

    testWidgets('opens on the saved notice, off', (tester) async {
      await pump(tester);

      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isFalse);
      expect(find.text('Old news'), findsWidgets); // field and preview
    });

    testWidgets('switching on without a message cannot be saved', (
      tester,
    ) async {
      when(() => repository.getForEditing())
          .thenAnswer((_) async => const Ok(AppNotice.off()));
      await pump(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      final save = tester.widget<MbButton>(find.byType(MbButton));
      expect(save.onPressed, isNull);
      expect(
        find.textContaining('Write the message users should see'),
        findsOneWidget,
      );
    });

    testWidgets('saves the type, the text and the switch as set', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Maintenance'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Back at 6 pm.');
      await tester.pump();
      await tester.ensureVisible(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();

      verify(() => repository.save(_maintenance)).called(1);
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('a failed first load shows an error', (tester) async {
      when(() => repository.getForEditing())
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });
  });

  test('the editor starts with nothing loaded', () {
    final cubit = AdminNoticeCubit(repository, AppNoticeCubit(repository));
    addTearDown(cubit.close);

    expect(cubit.state.notice.status, LoadStatus.initial);
  });
}
