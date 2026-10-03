import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/locale/locale_repository.dart';
import '../../../core/utils/data_state.dart';
import '../../../core/utils/statuses.dart';
import '../../account/presentation/profile_cubit.dart';
import '../../catalog/domain/catalog.dart';
import '../../markets/domain/mandi_prices.dart';
import '../domain/tools.dart';

class CostEstimatorState extends Equatable {
  const CostEstimatorState({
    this.categories = const DataState(),
    this.categoryCode,
    this.materials = const DataState(),
    this.materialId,
    this.states = const [],
    this.stateId,
    this.districts = const DataState(),
    this.districtId,
    this.quantityText = '',
    this.estimate = const DataState(),
    this.isSaved = false,
    this.saved = const DataState(),
    this.saveStatus = SubmitStatus.idle,
    this.saveFailure,
  });

  final DataState<List<NamedOption>> categories;
  final String? categoryCode;
  final DataState<List<EstimatorMaterial>> materials;
  final String? materialId;
  final List<LocationOption> states;
  final String? stateId;
  final DataState<List<LocationOption>> districts;

  /// `null` compares every location with prices.
  final String? districtId;
  final String quantityText;
  final DataState<Estimate> estimate;

  /// The shown estimate is kept in the saved list.
  final bool isSaved;
  final DataState<List<SavedEstimate>> saved;
  final SubmitStatus saveStatus;
  final Failure? saveFailure;

  EstimatorMaterial? get material =>
      materials.data?.where((m) => m.id == materialId).firstOrNull;

  EstimateRequest? get request {
    final quantity = num.tryParse(quantityText);
    final material = this.material;
    if (material == null || quantity == null || quantity <= 0) return null;
    return EstimateRequest(
      materialId: material.id,
      quantity: quantity,
      unitId: material.unit.id,
      districtId: districtId,
    );
  }

  bool get canSave =>
      estimate.status == LoadStatus.ready &&
      !isSaved &&
      saveStatus != SubmitStatus.submitting;

  CostEstimatorState copyWith({
    DataState<List<NamedOption>>? categories,
    ValueGetter<String?>? categoryCode,
    DataState<List<EstimatorMaterial>>? materials,
    ValueGetter<String?>? materialId,
    List<LocationOption>? states,
    ValueGetter<String?>? stateId,
    DataState<List<LocationOption>>? districts,
    ValueGetter<String?>? districtId,
    String? quantityText,
    DataState<Estimate>? estimate,
    bool? isSaved,
    DataState<List<SavedEstimate>>? saved,
    SubmitStatus? saveStatus,
    Failure? saveFailure,
  }) => CostEstimatorState(
    categories: categories ?? this.categories,
    categoryCode: categoryCode != null ? categoryCode() : this.categoryCode,
    materials: materials ?? this.materials,
    materialId: materialId != null ? materialId() : this.materialId,
    states: states ?? this.states,
    stateId: stateId != null ? stateId() : this.stateId,
    districts: districts ?? this.districts,
    districtId: districtId != null ? districtId() : this.districtId,
    quantityText: quantityText ?? this.quantityText,
    estimate: estimate ?? this.estimate,
    isSaved: isSaved ?? this.isSaved,
    saved: saved ?? this.saved,
    saveStatus: saveStatus ?? SubmitStatus.idle,
    saveFailure: saveFailure,
  );

  @override
  List<Object?> get props => [
    categories,
    categoryCode,
    materials,
    materialId,
    states,
    stateId,
    districts,
    districtId,
    quantityText,
    estimate,
    isSaved,
    saved,
    saveStatus,
    saveFailure,
  ];
}

/// Prices a quantity at every location with data via the Procurement API.
/// Each estimate is a requirement on the server: "Save" keeps it; one that
/// is replaced or left unsaved is deleted.
@injectable
class CostEstimatorCubit extends Cubit<CostEstimatorState> {
  CostEstimatorCubit(
    this._estimator,
    this._catalog,
    this._locations,
    this._profile,
  ) : super(const CostEstimatorState());

  final EstimatorRepository _estimator;
  final CatalogRepository _catalog;
  final MandiPricesRepository _locations;
  final ProfileCubit _profile;
  Timer? _debounce;

  /// Server-side requirement behind the shown estimate while it's unsaved.
  String? _draftId;

  Future<void> load() async {
    emit(state.copyWith(categories: const DataState.loading()));
    await _profile.ensureLoaded();
    final profile = _profile.state.data;
    final (categories, states, _) = await (
      _catalog.getCategories(),
      _locations.getStates(),
      _loadSaved(),
    ).wait;
    // Only the categories the user registered for.
    final options = categories.fold(
      (f) => null,
      (list) => [
        for (final c in userCategories(
          list,
          profile?.categoryCodes ?? const <String>[],
        ))
          NamedOption(id: c.code, name: c.name),
      ],
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        categories: options == null
            ? DataState(
                status: LoadStatus.failure,
                failure: categories.fold((f) => f, (_) => null),
              )
            : DataState.ready(options),
        states: states.fold((_) => const [], (s) => s),
      ),
    );
    if (options == null || options.isEmpty) return;
    // Start on the user's own category and district.
    final preferred = profile?.categoryCodes
        .where((code) => options.any((o) => o.id == code))
        .firstOrNull;
    final stateId = profile?.stateId;
    if (stateId != null && state.states.any((s) => s.id == stateId)) {
      await selectState(stateId, districtId: profile?.districtId);
    }
    await selectCategory(preferred ?? options.first.id);
  }

  Future<void> selectCategory(String code) async {
    if (code == state.categoryCode && state.materials.data != null) return;
    emit(
      state.copyWith(
        categoryCode: () => code,
        materials: const DataState.loading(),
        materialId: () => null,
      ),
    );
    final result = await _catalog.getProducts(code);
    if (isClosed || state.categoryCode != code) return;
    final materials = result.fold(
      (_) => null,
      (products) => [
        for (final p in products)
          EstimatorMaterial(
            id: p.id,
            name: p.name,
            categoryCode: code,
            unit: NamedOption(id: p.defaultUnit.id, name: p.defaultUnit.name),
          ),
      ],
    );
    emit(
      state.copyWith(
        materials: materials == null
            ? DataState(
                status: LoadStatus.failure,
                failure: result.fold((f) => f, (_) => null),
              )
            : DataState.ready(materials),
        materialId: () => materials?.firstOrNull?.id,
      ),
    );
    _schedule();
  }

  void selectMaterial(String id) {
    emit(state.copyWith(materialId: () => id));
    _schedule();
  }

  Future<void> selectState(String id, {String? districtId}) async {
    emit(
      state.copyWith(
        stateId: () => id,
        districts: const DataState.loading(),
        districtId: () => null,
      ),
    );
    final result = await _locations.getDistricts(id);
    if (isClosed || state.stateId != id) return;
    final districts = DataState.fromResult(result);
    final keep = districts.data?.any((d) => d.id == districtId) ?? false;
    emit(
      state.copyWith(
        districts: districts,
        districtId: () => keep ? districtId : null,
      ),
    );
    _schedule();
  }

  void selectDistrict(String? id) {
    emit(state.copyWith(districtId: () => id));
    _schedule();
  }

  void quantityChanged(String text) {
    emit(state.copyWith(quantityText: text.trim()));
    _schedule();
  }

  Future<void> retryEstimate() => _estimate();

  Future<void> retrySaved() => _loadSaved();

  /// Keeps the shown estimate's requirement.
  Future<void> save() async {
    if (!state.canSave) return;
    _draftId = null;
    emit(state.copyWith(isSaved: true, saveStatus: SubmitStatus.success));
    await _loadSaved();
  }

  /// Shows a saved estimate re-priced against today's prices.
  Future<void> openSaved(SavedEstimate saved) async {
    _debounce?.cancel();
    await _discardDraft();
    emit(
      state.copyWith(
        estimate: DataState.loading(data: state.estimate.data),
        isSaved: true,
      ),
    );
    final result = await _estimator.reprice(saved);
    if (isClosed) return;
    emit(state.copyWith(estimate: DataState.fromResult(result)));
  }

  Future<void> deleteSaved(SavedEstimate saved) async {
    final result = await _estimator.delete(saved.id);
    if (isClosed) return;
    if (result case Err(:final failure)) {
      emit(
        state.copyWith(saveStatus: SubmitStatus.failure, saveFailure: failure),
      );
      return;
    }
    if (state.estimate.data?.requirementId == saved.id) {
      emit(state.copyWith(estimate: const DataState(), isSaved: false));
    }
    await _loadSaved();
  }

  Future<void> _loadSaved() async {
    emit(state.copyWith(saved: DataState.loading(data: state.saved.data)));
    final result = await _estimator.getSaved();
    if (isClosed) return;
    // The unsaved draft is a requirement too; it isn't a saved estimate.
    emit(
      state.copyWith(
        saved: DataState.fromResult(
          result.fold<Result<List<SavedEstimate>>>(
            (f) => Err(f),
            (list) => Ok([
              for (final s in list)
                if (s.id != _draftId) s,
            ]),
          ),
        ),
      ),
    );
  }

  /// Recalculates shortly after the user stops editing.
  void _schedule() {
    _debounce?.cancel();
    if (state.request == null) {
      unawaited(_discardDraft());
      emit(state.copyWith(estimate: const DataState(), isSaved: false));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), _estimate);
  }

  Future<void> _estimate() async {
    final request = state.request;
    if (request == null) return;
    emit(
      state.copyWith(
        estimate: DataState.loading(data: state.estimate.data),
        isSaved: false,
      ),
    );
    await _discardDraft();
    final result = await _estimator.estimate(request);
    final id = result is Ok<Estimate> ? result.value.requirementId : null;
    if (isClosed || state.request != request) {
      // Left the screen or changed the inputs meanwhile: this one is stale.
      if (id != null) await _estimator.delete(id);
      return;
    }
    _draftId = id;
    emit(state.copyWith(estimate: DataState.fromResult(result)));
  }

  Future<void> _discardDraft() async {
    final id = _draftId;
    _draftId = null;
    if (id != null) await _estimator.delete(id);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    unawaited(_discardDraft());
    return super.close();
  }
}

// --- Reports ---------------------------------------------------------------

enum ReportRange { week, month, quarter, custom }

class ReportsState extends Equatable {
  const ReportsState({
    this.reports = const DataState(),
    this.kind = ReportKind.weeklySummary,
    this.range = ReportRange.week,
    this.customFrom,
    this.customTo,
    this.language,
    this.categories = const [],
    this.categoryCode,
    this.products = const DataState(),
    this.productId,
    this.states = const [],
    this.stateId,
    this.districts = const DataState(),
    this.districtId,
    this.mandis = const DataState(),
    this.mandiId,
    this.submitStatus = SubmitStatus.idle,
    this.failure,
    this.downloadingId,
    this.readyId,
  });

  final DataState<List<GeneratedReport>> reports;
  final ReportKind kind;
  final ReportRange range;
  final DateTime? customFrom;
  final DateTime? customTo;

  /// Report language code; defaults to the profile's preferred language.
  final String? language;

  // Price history CSV: product and optional mandi.
  final List<CatalogCategory> categories;
  final String? categoryCode;
  final DataState<List<CatalogProduct>> products;
  final String? productId;
  final List<LocationOption> states;
  final String? stateId;
  final DataState<List<LocationOption>> districts;
  final String? districtId;
  final DataState<List<LocationOption>> mandis;
  final String? mandiId;

  final SubmitStatus submitStatus;

  /// Last failed action (generate, download), shown once.
  final Failure? failure;
  final String? downloadingId;

  /// A report generated in this session that just became ready.
  final String? readyId;

  bool get isGenerating => submitStatus == SubmitStatus.submitting;

  /// Inclusive dates the report covers, ending today unless custom.
  (DateTime, DateTime)? get period {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (range) {
      ReportRange.week => (today.subtract(const Duration(days: 6)), today),
      ReportRange.month => (today.subtract(const Duration(days: 29)), today),
      ReportRange.quarter => (today.subtract(const Duration(days: 89)), today),
      ReportRange.custom when customFrom != null && customTo != null => (
        customFrom!,
        customTo!,
      ),
      ReportRange.custom => null,
    };
  }

  bool get canGenerate =>
      !isGenerating &&
      period != null &&
      language != null &&
      (kind == ReportKind.weeklySummary || productId != null);

  ReportsState copyWith({
    DataState<List<GeneratedReport>>? reports,
    ReportKind? kind,
    ReportRange? range,
    ValueGetter<DateTime?>? customFrom,
    ValueGetter<DateTime?>? customTo,
    String? language,
    List<CatalogCategory>? categories,
    ValueGetter<String?>? categoryCode,
    DataState<List<CatalogProduct>>? products,
    ValueGetter<String?>? productId,
    List<LocationOption>? states,
    ValueGetter<String?>? stateId,
    DataState<List<LocationOption>>? districts,
    ValueGetter<String?>? districtId,
    DataState<List<LocationOption>>? mandis,
    ValueGetter<String?>? mandiId,
    SubmitStatus? submitStatus,
    Failure? failure,
    ValueGetter<String?>? downloadingId,
    ValueGetter<String?>? readyId,
  }) => ReportsState(
    reports: reports ?? this.reports,
    kind: kind ?? this.kind,
    range: range ?? this.range,
    customFrom: customFrom != null ? customFrom() : this.customFrom,
    customTo: customTo != null ? customTo() : this.customTo,
    language: language ?? this.language,
    categories: categories ?? this.categories,
    categoryCode: categoryCode != null ? categoryCode() : this.categoryCode,
    products: products ?? this.products,
    productId: productId != null ? productId() : this.productId,
    states: states ?? this.states,
    stateId: stateId != null ? stateId() : this.stateId,
    districts: districts ?? this.districts,
    districtId: districtId != null ? districtId() : this.districtId,
    mandis: mandis ?? this.mandis,
    mandiId: mandiId != null ? mandiId() : this.mandiId,
    submitStatus: submitStatus ?? this.submitStatus,
    failure: failure,
    downloadingId: downloadingId != null ? downloadingId() : this.downloadingId,
    readyId: readyId != null ? readyId() : this.readyId,
  );

  @override
  List<Object?> get props => [
    reports,
    kind,
    range,
    customFrom,
    customTo,
    language,
    categories,
    categoryCode,
    products,
    productId,
    states,
    stateId,
    districts,
    districtId,
    mandis,
    mandiId,
    submitStatus,
    failure,
    downloadingId,
    readyId,
  ];
}

/// Generate form + the user's reports. A requested report is polled until
/// it is ready (or failed).
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(
    this._reports,
    this._catalog,
    this._locations,
    this._profile,
    this._locale,
  ) : super(const ReportsState());

  final ReportsRepository _reports;
  final CatalogRepository _catalog;
  final MandiPricesRepository _locations;
  final ProfileCubit _profile;
  final LocaleRepository _locale;
  Timer? _poll;

  static const _pollEvery = Duration(seconds: 2);
  static const _pollFor = Duration(minutes: 2);

  Future<void> load() async {
    emit(
      state.copyWith(
        reports: DataState.loading(data: state.reports.data),
        language:
            state.language ??
            _profile.state.data?.preferredLanguage ??
            _locale.current.code,
      ),
    );
    await _refreshList();
  }

  void selectKind(ReportKind kind) {
    emit(state.copyWith(kind: kind));
    if (kind == ReportKind.priceHistoryCsv && state.categories.isEmpty) {
      unawaited(_loadCsvOptions());
    }
  }

  void selectRange(ReportRange range) => emit(state.copyWith(range: range));

  void setCustomRange(DateTime from, DateTime to) => emit(
    state.copyWith(
      range: ReportRange.custom,
      customFrom: () => from,
      customTo: () => to,
    ),
  );

  void selectLanguage(String code) => emit(state.copyWith(language: code));

  Future<void> selectCategory(String code) async {
    emit(
      state.copyWith(
        categoryCode: () => code,
        products: const DataState.loading(),
        productId: () => null,
      ),
    );
    final result = await _catalog.getProducts(code);
    if (isClosed || state.categoryCode != code) return;
    emit(state.copyWith(products: DataState.fromResult(result)));
  }

  void selectProduct(String id) => emit(state.copyWith(productId: () => id));

  Future<void> selectState(String id) async {
    emit(
      state.copyWith(
        stateId: () => id,
        districts: const DataState.loading(),
        districtId: () => null,
        mandis: const DataState(),
        mandiId: () => null,
      ),
    );
    final result = await _locations.getDistricts(id);
    if (isClosed || state.stateId != id) return;
    emit(state.copyWith(districts: DataState.fromResult(result)));
  }

  Future<void> selectDistrict(String id) async {
    emit(
      state.copyWith(
        districtId: () => id,
        mandis: const DataState.loading(),
        mandiId: () => null,
      ),
    );
    final result = await _locations.getMandis(id);
    if (isClosed || state.districtId != id) return;
    emit(state.copyWith(mandis: DataState.fromResult(result)));
  }

  /// `null` = all mandis.
  void selectMandi(String? id) => emit(state.copyWith(mandiId: () => id));

  Future<void> generate() async {
    final period = state.period;
    final language = state.language;
    if (!state.canGenerate || period == null || language == null) return;
    emit(
      state.copyWith(
        submitStatus: SubmitStatus.submitting,
        readyId: () => null,
      ),
    );
    final result = await _reports.request(
      ReportRequest(
        kind: state.kind,
        from: period.$1,
        to: period.$2,
        language: language,
        productId: state.kind == ReportKind.priceHistoryCsv
            ? state.productId
            : null,
        mandiId: state.kind == ReportKind.priceHistoryCsv
            ? state.mandiId
            : null,
      ),
    );
    if (isClosed) return;
    switch (result) {
      case Err(:final failure):
        emit(
          state.copyWith(submitStatus: SubmitStatus.failure, failure: failure),
        );
      case Ok(value: final id):
        await _refreshList();
        _startPolling(id);
    }
  }

  Future<void> download(GeneratedReport report) async {
    if (state.downloadingId != null) return;
    emit(state.copyWith(downloadingId: () => report.id));
    final result = await _reports.download(report.id);
    if (isClosed) return;
    emit(
      state.copyWith(
        downloadingId: () => null,
        failure: result.fold((f) => f, (_) => null),
      ),
    );
    if (result case Ok(value: final file)) {
      _downloaded.add(file);
      // The API stamped lastDownloadedAtUtc on the way out — refetch so the
      // row shows "Downloaded …".
      await _refreshList();
    }
  }

  /// Files ready to hand to the platform (the page saves/opens them).
  final _downloaded = StreamController<DownloadedFile>.broadcast();

  Stream<DownloadedFile> get downloads => _downloaded.stream;

  Future<void> _loadCsvOptions() async {
    final (categories, states) = await (
      _catalog.getCategories(),
      _locations.getStates(),
    ).wait;
    if (isClosed) return;
    final list = categories.fold((_) => const <CatalogCategory>[], (c) => c);
    emit(
      state.copyWith(
        categories: list,
        states: states.fold((_) => const [], (s) => s),
      ),
    );
    final first = list.firstOrNull;
    if (first != null) await selectCategory(first.code);
  }

  void _startPolling(String id) {
    _poll?.cancel();
    final until = DateTime.now().add(_pollFor);
    _poll = Timer.periodic(_pollEvery, (timer) async {
      final result = await _reports.getReport(id);
      if (isClosed) return timer.cancel();
      final report = result.fold((_) => null, (r) => r);
      final done = report != null && report.status != ReportStatus.pending;
      if (done || DateTime.now().isAfter(until)) {
        timer.cancel();
        await _refreshList();
        if (isClosed) return;
        emit(
          state.copyWith(
            submitStatus: SubmitStatus.idle,
            readyId: () =>
                report?.status == ReportStatus.ready ? report!.id : null,
          ),
        );
      }
    });
  }

  Future<void> _refreshList() async {
    final result = await _reports.getReports();
    if (isClosed) return;
    emit(
      state.copyWith(
        reports: result.fold(
          (f) => state.reports.data == null
              ? DataState(status: LoadStatus.failure, failure: f)
              : DataState.ready(state.reports.data!),
          DataState.ready,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    _downloaded.close();
    return super.close();
  }
}
