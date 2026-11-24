import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mol_bhav/core/error/failure.dart';
import 'package:mol_bhav/core/error/result.dart';
import 'package:mol_bhav/core/utils/statuses.dart';
import 'package:mol_bhav/features/admin/data/admin_campaigns_data.dart';
import 'package:mol_bhav/features/admin/domain/admin_ads.dart';
import 'package:mol_bhav/features/admin/domain/admin_campaigns.dart';
import 'package:mol_bhav/features/admin/domain/admin_ingestion.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_form_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_form_page.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_list_cubit.dart';
import 'package:mol_bhav/features/admin/presentation/admin_campaign_list_page.dart';
import 'package:mol_bhav/shared/widgets/mb_button.dart';

import '../../helpers/pump_app.dart';

class _MockCampaigns extends Mock implements AdminCampaignsRepository {}

class _MockIngestion extends Mock implements AdminIngestionRepository {}

const _advertiser = AdminAdvertiser(id: 'a1', name: 'Tata Agri Ltd');

final _valid = CampaignDraft(
  advertiserId: 'a1',
  name: 'Monsoon Sale',
  title: 'Monsoon offers',
  body: 'Seeds and fertiliser at special prices.',
  ctaLabel: 'Shop now',
  ctaUrl: 'https://example.com/monsoon',
  startsOn: DateTime(2026, 11, 1),
  endsOn: DateTime(2026, 11, 30),
  priority: '5',
  categoryCodes: const {'agriculture'},
);

AdminCampaign _campaign({
  String id = 'c1',
  CampaignState status = CampaignState.draft,
  List<CampaignTarget>? targets,
}) => AdminCampaign(
  id: id,
  advertiserId: 'a1',
  advertiserName: 'Tata Agri Ltd',
  name: 'Monsoon Sale',
  placement: AdPlacement.homeFeed,
  status: status,
  startsAt: DateTime(2026, 11, 1),
  endsAt: DateTime(2026, 11, 30, 23, 59, 59),
  priority: 5,
  dailyCap: 500,
  title: 'Monsoon offers',
  body: 'Seeds and fertiliser at special prices.',
  ctaLabel: 'Shop now',
  ctaUrl: 'https://example.com/monsoon',
  targets: targets ?? const [CampaignTarget(categoryCode: 'agriculture')],
);

void main() {
  late _MockCampaigns campaigns;
  late _MockIngestion ingestion;

  setUpAll(() {
    registerFallbackValue(const CampaignDraft());
    registerFallbackValue(CampaignAction.activate);
  });

  setUp(() {
    campaigns = _MockCampaigns();
    ingestion = _MockIngestion();
    when(() => campaigns.getAdvertisers())
        .thenAnswer((_) async => const Ok([_advertiser]));
    when(() => campaigns.getStates()).thenAnswer(
      (_) async => const Ok([AdminState(id: 's1', name: 'Gujarat')]),
    );
    when(() => ingestion.getCategories()).thenAnswer(
      (_) async => const Ok([
        AdminCategory(code: 'agriculture', name: 'Agriculture'),
        AdminCategory(code: 'construction', name: 'Construction'),
      ]),
    );
    when(
      () => campaigns.getCampaigns(
        status: any(named: 'status'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => Ok([_campaign()]));
    when(() => campaigns.createCampaign(any()))
        .thenAnswer((_) async => const Ok('new1'));
    when(() => campaigns.updateCampaign(any(), any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => campaigns.setStatus(any(), any()))
        .thenAnswer((_) async => const Ok(null));
  });

  group('the draft', () {
    test('a complete one has no problems', () {
      expect(campaignProblems(_valid), isEmpty);
    });

    test('each rule the API applies is checked', () {
      expect(
        campaignProblems(const CampaignDraft()),
        containsAll([
          CampaignProblem.advertiserMissing,
          CampaignProblem.nameInvalid,
          CampaignProblem.titleInvalid,
          CampaignProblem.bodyInvalid,
          CampaignProblem.ctaLabelInvalid,
          CampaignProblem.ctaUrlInvalid,
          CampaignProblem.startMissing,
          CampaignProblem.endMissing,
          CampaignProblem.categoriesMissing,
        ]),
      );
      expect(campaignProblems(_valid.copyWith(title: 'x' * 61)), {
        CampaignProblem.titleInvalid,
      });
      expect(campaignProblems(_valid.copyWith(body: 'x' * 141)), {
        CampaignProblem.bodyInvalid,
      });
      expect(campaignProblems(_valid.copyWith(ctaLabel: 'x' * 25)), {
        CampaignProblem.ctaLabelInvalid,
      });
    });

    test('links must be https; the image link may be empty', () {
      expect(campaignProblems(_valid.copyWith(ctaUrl: 'http://example.com')), {
        CampaignProblem.ctaUrlInvalid,
      });
      expect(campaignProblems(_valid.copyWith(ctaUrl: 'example.com/x')), {
        CampaignProblem.ctaUrlInvalid,
      });
      expect(campaignProblems(_valid.copyWith(imageUrl: 'ftp://x.com/a.png')), {
        CampaignProblem.imageUrlInvalid,
      });
      expect(
        campaignProblems(_valid.copyWith(imageUrl: 'https://x.com/a.png')),
        isEmpty,
      );
    });

    test('the end may not come before the start', () {
      expect(
        campaignProblems(_valid.copyWith(endsOn: () => DateTime(2026, 10, 31))),
        {CampaignProblem.endBeforeStart},
      );
      // The same day is a one-day campaign.
      expect(
        campaignProblems(_valid.copyWith(endsOn: () => DateTime(2026, 11, 1))),
        isEmpty,
      );
    });

    test('priority is 0 to 100; the daily limit is empty or 1 or more', () {
      expect(campaignProblems(_valid.copyWith(priority: '101')), {
        CampaignProblem.priorityInvalid,
      });
      expect(campaignProblems(_valid.copyWith(priority: '')), {
        CampaignProblem.priorityInvalid,
      });
      expect(campaignProblems(_valid.copyWith(dailyCap: '0')), {
        CampaignProblem.dailyCapInvalid,
      });
      expect(campaignProblems(_valid.copyWith(dailyCap: '250')), isEmpty);
    });

    test('the request holds every category in every chosen state', () {
      final json = _valid
          .copyWith(
            categoryCodes: {'agriculture', 'construction'},
            stateIds: {'s1', 's2'},
            dailyCap: '300',
          )
          .toJson();

      expect(json['name'], 'Monsoon Sale');
      expect(json['placement'], 'HomeFeed');
      expect(json['imageUrl'], isNull);
      expect(json['dailyImpressionCap'], 300);
      expect(json['priority'], 5);
      final targets = [
        for (final t in json['targets']! as List<Map<String, String?>>)
          '${t['categoryCode']}/${t['stateId']}',
      ];
      expect(targets, hasLength(4));
      expect(
        targets,
        containsAll([
          'agriculture/s1',
          'agriculture/s2',
          'construction/s1',
          'construction/s2',
        ]),
      );
    });

    test('with no state chosen the campaign is for every state', () {
      final targets = _valid.toJson()['targets']! as List;

      expect(targets, [
        {'categoryCode': 'agriculture', 'stateId': null},
      ]);
    });

    test('the days become the first and last second, in UTC', () {
      expect(_valid.startsAt, DateTime(2026, 11, 1).toUtc());
      expect(_valid.endsAt, DateTime(2026, 11, 30, 23, 59, 59).toUtc());
    });

    test('an existing campaign becomes a draft for editing', () {
      final draft = CampaignDraft.from(_campaign());

      expect(draft.name, 'Monsoon Sale');
      expect(draft.dailyCap, '500');
      expect(draft.categoryCodes, {'agriculture'});
      expect(draft.startsOn, DateTime(2026, 11, 1));
      expect(campaignProblems(draft), isEmpty);
    });

    test('targets the form can express are recognised; others are not', () {
      expect(_campaign().targetsFitForm, isTrue);
      expect(
        _campaign(
          targets: const [
            CampaignTarget(categoryCode: 'agriculture', stateId: 's1'),
            CampaignTarget(categoryCode: 'construction', stateId: 's1'),
          ],
        ).targetsFitForm,
        isTrue,
      );
      // Construction only in one state, agriculture everywhere: not a product.
      expect(
        _campaign(
          targets: const [
            CampaignTarget(categoryCode: 'agriculture'),
            CampaignTarget(categoryCode: 'construction', stateId: 's1'),
          ],
        ).targetsFitForm,
        isFalse,
      );
    });
  });

  test('an API campaign is read, unknown values kept safe', () {
    final c = AdminCampaignsRepositoryImpl.parseCampaign({
      'id': 'c9',
      'advertiserId': 'a1',
      'advertiserName': 'Tata Agri Ltd',
      'name': 'Sale',
      'placement': 'MandiPrices',
      'status': 'Active',
      'startsAtUtc': '2026-11-01T00:00:00+00:00',
      'endsAtUtc': '2026-11-30T23:59:59+00:00',
      'priority': 7,
      'dailyImpressionCap': null,
      'title': 'T',
      'body': 'B',
      'ctaLabel': 'Go',
      'ctaUrl': 'https://example.com',
      'imageUrl': null,
      'targets': [
        {'categoryCode': 'agriculture', 'stateId': null},
        {'categoryCode': 'construction', 'stateId': 's1'},
      ],
    });

    expect(c.placement, AdPlacement.mandiPrices);
    expect(c.status, CampaignState.active);
    expect(c.dailyCap, isNull);
    expect(c.imageUrl, isNull);
    expect(c.targets.last.stateId, 's1');
    expect(AdPlacement.fromWire('SomethingNew'), AdPlacement.homeFeed);
  });

  group('AdminCampaignListCubit', () {
    late AdminCampaignListCubit cubit;

    setUp(() => cubit = AdminCampaignListCubit(campaigns));
    tearDown(() => cubit.close());

    test('loads every campaign first', () async {
      await cubit.load();

      expect(cubit.state.campaigns, hasLength(1));
      verify(
        () => campaigns.getCampaigns(
          status: null,
          page: 1,
          pageSize: AdminCampaignListCubit.pageSize,
        ),
      ).called(1);
    });

    test('a filter reloads for that state', () async {
      await cubit.load();

      await cubit.setFilter(CampaignState.active);

      expect(cubit.state.filter, CampaignState.active);
      verify(
        () => campaigns.getCampaigns(
          status: CampaignState.active,
          page: 1,
          pageSize: AdminCampaignListCubit.pageSize,
        ),
      ).called(1);
    });

    test('a failed load is a failure', () async {
      when(
        () => campaigns.getCampaigns(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.failure);
    });
  });

  group('AdminCampaignFormCubit', () {
    late AdminCampaignFormCubit cubit;

    setUp(() => cubit = AdminCampaignFormCubit(campaigns, ingestion));
    tearDown(() => cubit.close());

    test('loads the advertisers, categories and states to pick from', () async {
      await cubit.load();

      final setup = cubit.state.setup.data!;
      expect(setup.advertisers, [_advertiser]);
      expect(setup.categories, hasLength(2));
      expect(setup.states.single.name, 'Gujarat');
    });

    test('one pick-list failing is a failure of the form', () async {
      when(() => campaigns.getStates())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await cubit.load();

      expect(cubit.state.setup.status, LoadStatus.failure);
    });

    test('editing starts from the campaign', () async {
      await cubit.load(campaign: _campaign());

      expect(cubit.state.draft.name, 'Monsoon Sale');
    });

    test('a complete draft is created', () async {
      await cubit.load();
      cubit.edit(_valid);

      await cubit.save();

      verify(() => campaigns.createCampaign(_valid)).called(1);
      expect(cubit.state.outcome, CampaignFormOutcome.created);
    });

    test('an incomplete draft is not sent', () async {
      await cubit.load();

      await cubit.save();

      verifyNever(() => campaigns.createCampaign(any()));
      expect(cubit.state.outcome, CampaignFormOutcome.none);
    });

    test('an edit updates that campaign', () async {
      await cubit.load(campaign: _campaign());

      await cubit.save();

      verify(() => campaigns.updateCampaign('c1', any())).called(1);
      expect(cubit.state.outcome, CampaignFormOutcome.updated);
    });

    test('a refusal is kept to be shown, with nothing done', () async {
      when(() => campaigns.createCampaign(any())).thenAnswer(
        (_) async => const Err(ServerFailure(message: 'Unknown advertiser.')),
      );
      await cubit.load();
      cubit.edit(_valid);

      await cubit.save();

      expect(cubit.state.outcome, CampaignFormOutcome.none);
      expect(cubit.state.failure, isA<ServerFailure>());
      cubit.failureShown();
      expect(cubit.state.failure, isNull);
    });

    test('a status change goes to that campaign', () async {
      await cubit.load(campaign: _campaign());

      await cubit.setStatus(CampaignAction.activate);

      verify(() => campaigns.setStatus('c1', CampaignAction.activate))
          .called(1);
      expect(cubit.state.outcome, CampaignFormOutcome.statusChanged);
    });

    test('a new campaign has no status to change', () async {
      await cubit.load();

      await cubit.setStatus(CampaignAction.activate);

      verifyNever(() => campaigns.setStatus(any(), any()));
    });

    test('a new advertiser is added, listed and chosen', () async {
      when(
        () => campaigns.createAdvertiser(
          name: any(named: 'name'),
          contactName: any(named: 'contactName'),
          contactPhone: any(named: 'contactPhone'),
          gstin: any(named: 'gstin'),
        ),
      ).thenAnswer((_) async => const Ok('a2'));
      when(() => campaigns.getAdvertisers()).thenAnswer(
        (_) async => const Ok([
          _advertiser,
          AdminAdvertiser(id: 'a2', name: 'Kisan Seeds'),
        ]),
      );
      await cubit.load();

      final ok = await cubit.addAdvertiser(name: 'Kisan Seeds');

      expect(ok, isTrue);
      expect(cubit.state.setup.data!.advertisers, hasLength(2));
      expect(cubit.state.draft.advertiserId, 'a2');
    });
  });

  group('AdminCampaignListPage', () {
    testWidgets('lists campaigns with status and advertiser', (tester) async {
      final cubit = AdminCampaignListCubit(campaigns);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminCampaignListPage()),
      );

      expect(find.text('Monsoon Sale'), findsOneWidget);
      expect(find.textContaining('Tata Agri Ltd'), findsOneWidget);
      expect(find.text('Draft'), findsWidgets);
      expect(find.text('New campaign'), findsOneWidget);
    });

    testWidgets('an empty list says so', (tester) async {
      when(
        () => campaigns.getCampaigns(
          status: any(named: 'status'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Ok([]));
      final cubit = AdminCampaignListCubit(campaigns);
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const AdminCampaignListPage()),
      );

      expect(find.text('No campaigns here.'), findsOneWidget);
    });
  });

  group('AdminCampaignFormPage', () {
    Future<AdminCampaignFormCubit> pump(
      WidgetTester tester, {
      AdminCampaign? campaign,
      CampaignDraft? draft,
    }) async {
      final cubit = AdminCampaignFormCubit(campaigns, ingestion);
      addTearDown(cubit.close);
      await cubit.load(campaign: campaign);
      if (draft != null) cubit.edit(draft);
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: AdminCampaignFormPage(campaign: campaign),
        ),
      );
      return cubit;
    }

    testWidgets('saving a complete new campaign creates it as a draft', (
      tester,
    ) async {
      await pump(tester, draft: _valid);

      await tester.scrollUntilVisible(
        find.text('Save campaign'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save campaign'));
      await tester.pumpAndSettle();

      verify(() => campaigns.createCampaign(_valid)).called(1);
    });

    testWidgets(
      'saving an incomplete one shows what is missing, sends nothing',
      (tester) async {
        await pump(tester);

        await tester.scrollUntilVisible(
          find.text('Save campaign'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Save campaign'));
        await tester.pump();

        // The form is a long lazy list: scroll back up to the messages.
        final list = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Choose at least one category'),
          -300,
          scrollable: list,
        );
        expect(find.text('Choose at least one category'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Required'),
          -300,
          scrollable: list,
        );
        expect(find.text('Required'), findsWidgets);
        verifyNever(() => campaigns.createCampaign(any()));
      },
    );

    testWidgets('a draft campaign can be activated or ended, not paused', (
      tester,
    ) async {
      await pump(tester, campaign: _campaign());
      await tester.scrollUntilVisible(
        find.text('Activate'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Activate'), findsOneWidget);
      expect(find.text('End campaign'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('an active campaign can be paused', (tester) async {
      await pump(tester, campaign: _campaign(status: CampaignState.active));
      await tester.scrollUntilVisible(
        find.text('Pause'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Activate'), findsNothing);
    });

    testWidgets('activating goes straight through', (tester) async {
      await pump(tester, campaign: _campaign());
      await tester.scrollUntilVisible(
        find.text('Activate'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Activate'));
      await tester.pumpAndSettle();

      verify(() => campaigns.setStatus('c1', CampaignAction.activate))
          .called(1);
    });

    testWidgets('ending asks first, and Cancel keeps the campaign', (
      tester,
    ) async {
      await pump(tester, campaign: _campaign(status: CampaignState.active));
      await tester.scrollUntilVisible(
        find.text('End campaign'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('End campaign'));
      await tester.pumpAndSettle();
      expect(find.text('End this campaign?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => campaigns.setStatus(any(), any()));
    });

    testWidgets('an ended campaign is read-only', (tester) async {
      await pump(tester, campaign: _campaign(status: CampaignState.ended));

      expect(find.textContaining('This campaign has ended'), findsOneWidget);
      expect(find.text('Save campaign'), findsNothing);
      expect(find.text('Activate'), findsNothing);
      expect(
        tester
            .widgetList<MbButton>(find.byType(MbButton))
            .where((b) => b.label == 'Save campaign'),
        isEmpty,
      );
    });

    testWidgets('targeting the form cannot show is called out', (tester) async {
      await pump(
        tester,
        campaign: _campaign(
          targets: const [
            CampaignTarget(categoryCode: 'agriculture'),
            CampaignTarget(categoryCode: 'construction', stateId: 's1'),
          ],
        ),
      );

      expect(find.textContaining('targeted in more detail'), findsOneWidget);
    });

    testWidgets('a failed load of the pick-lists shows an error', (
      tester,
    ) async {
      when(() => campaigns.getAdvertisers())
          .thenAnswer((_) async => const Err(NetworkFailure()));

      await pump(tester);

      expect(find.textContaining('No internet connection'), findsOneWidget);
    });

    testWidgets('the preview follows what is typed', (tester) async {
      await pump(tester, draft: _valid);
      await tester.scrollUntilVisible(
        find.text('Preview'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Monsoon offers'), findsWidgets);
      expect(find.textContaining('Sponsored · Tata Agri Ltd'), findsOneWidget);
    });
  });
}
