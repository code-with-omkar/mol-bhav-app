import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../domain/admin_campaigns.dart';
import '../domain/admin_ingestion.dart';

/// What the form's pickers offer.
class CampaignFormSetup extends Equatable {
  const CampaignFormSetup({
    required this.advertisers,
    required this.categories,
    required this.states,
  });

  final List<AdminAdvertiser> advertisers;
  final List<AdminCategory> categories;
  final List<AdminState> states;

  @override
  List<Object?> get props => [advertisers, categories, states];
}

/// What a finished action did, so the page can say so and close.
enum CampaignFormOutcome { none, created, updated, statusChanged }

class AdminCampaignFormState extends Equatable {
  const AdminCampaignFormState({
    this.setup = const DataState(),
    this.draft = const CampaignDraft(),
    this.busy = false,
    this.outcome = CampaignFormOutcome.none,
    this.failure,
  });

  final DataState<CampaignFormSetup> setup;
  final CampaignDraft draft;

  /// A save, status change or new advertiser is in flight.
  final bool busy;
  final CampaignFormOutcome outcome;

  /// Why the last action failed (shown once, then cleared).
  final Failure? failure;

  AdminCampaignFormState copyWith({
    DataState<CampaignFormSetup>? setup,
    CampaignDraft? draft,
    bool? busy,
    CampaignFormOutcome? outcome,
    Failure? Function()? failure,
  }) => AdminCampaignFormState(
    setup: setup ?? this.setup,
    draft: draft ?? this.draft,
    busy: busy ?? this.busy,
    outcome: outcome ?? this.outcome,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [setup, draft, busy, outcome, failure];
}

/// Create a campaign, or edit (and activate, pause or end) an existing one.
@injectable
class AdminCampaignFormCubit extends Cubit<AdminCampaignFormState> {
  AdminCampaignFormCubit(this._campaigns, this._ingestion)
    : super(const AdminCampaignFormState());

  final AdminCampaignsRepository _campaigns;
  final AdminIngestionRepository _ingestion;

  /// The campaign being edited; null when creating.
  AdminCampaign? _editing;

  /// Loads the pickers; [campaign] is the one to edit, or null for a new one.
  Future<void> load({AdminCampaign? campaign}) async {
    _editing = campaign;
    emit(
      state.copyWith(
        setup: DataState.loading(data: state.setup.data),
        draft: campaign == null ? state.draft : CampaignDraft.from(campaign),
      ),
    );
    final (advertisers, categories, states) = await (
      _campaigns.getAdvertisers(),
      _ingestion.getCategories(),
      _campaigns.getStates(),
    ).wait;
    if (isClosed) return;
    final failure = [
      advertisers,
      categories,
      states,
    ].whereType<Err<Object?>>().map((e) => e.failure).firstOrNull;
    if (failure != null) {
      emit(
        state.copyWith(
          setup: DataState(status: LoadStatus.failure, failure: failure),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        setup: DataState.ready(
          CampaignFormSetup(
            advertisers: (advertisers as Ok<List<AdminAdvertiser>>).value,
            categories: (categories as Ok<List<AdminCategory>>).value,
            states: (states as Ok<List<AdminState>>).value,
          ),
        ),
      ),
    );
  }

  /// Replaces the form values (the page calls this on every edit).
  void edit(CampaignDraft draft) => emit(state.copyWith(draft: draft));

  /// Saves the draft: a new campaign (as a draft campaign) or the edit.
  Future<void> save() async {
    if (state.busy || campaignProblems(state.draft).isNotEmpty) return;
    emit(state.copyWith(busy: true, failure: () => null));
    final editing = _editing;
    final Result<void> result;
    if (editing == null) {
      final created = await _campaigns.createCampaign(state.draft);
      result = created.fold<Result<void>>(
        (failure) => Err<void>(failure),
        (_) => const Ok<void>(null),
      );
    } else {
      result = await _campaigns.updateCampaign(editing.id, state.draft);
    }
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(busy: false, failure: () => failure)),
      (_) => emit(
        state.copyWith(
          busy: false,
          outcome: editing == null
              ? CampaignFormOutcome.created
              : CampaignFormOutcome.updated,
        ),
      ),
    );
  }

  Future<void> setStatus(CampaignAction action) async {
    final editing = _editing;
    if (editing == null || state.busy) return;
    emit(state.copyWith(busy: true, failure: () => null));
    final result = await _campaigns.setStatus(editing.id, action);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(busy: false, failure: () => failure)),
      (_) => emit(
        state.copyWith(busy: false, outcome: CampaignFormOutcome.statusChanged),
      ),
    );
  }

  /// Adds an advertiser, then offers (and picks) it in the form.
  Future<bool> addAdvertiser({
    required String name,
    String? contactName,
    String? contactPhone,
    String? gstin,
  }) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true, failure: () => null));
    final created = await _campaigns.createAdvertiser(
      name: name,
      contactName: contactName,
      contactPhone: contactPhone,
      gstin: gstin,
    );
    if (isClosed) return false;
    switch (created) {
      case Err<String>(:final failure):
        emit(state.copyWith(busy: false, failure: () => failure));
        return false;
      case Ok<String>(:final value):
        final advertisers = await _campaigns.getAdvertisers();
        if (isClosed) return false;
        final setup = state.setup.data;
        emit(
          state.copyWith(
            busy: false,
            setup: advertisers.fold(
              (_) => state.setup,
              (list) => setup == null
                  ? state.setup
                  : DataState.ready(
                      CampaignFormSetup(
                        advertisers: list,
                        categories: setup.categories,
                        states: setup.states,
                      ),
                    ),
            ),
            draft: state.draft.copyWith(advertiserId: () => value),
          ),
        );
        return true;
    }
  }

  void failureShown() => emit(state.copyWith(failure: () => null));
}
