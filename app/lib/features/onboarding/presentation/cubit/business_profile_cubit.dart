import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/locale/app_language.dart';
import '../../../../core/locale/locale_repository.dart';
import '../../../../core/utils/statuses.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class BusinessProfileState extends Equatable {
  const BusinessProfileState({
    required this.language,
    this.optionsStatus = LoadStatus.initial,
    this.options,
    this.optionsFailure,
    this.businessTypeId,
    this.stateCode,
    this.districtCode,
    this.districtsStatus = LoadStatus.initial,
    this.districts = const [],
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
  });

  final AppLanguage language;
  final LoadStatus optionsStatus;
  final ProfileOptions? options;
  final Failure? optionsFailure;
  final String? businessTypeId;
  final String? stateCode;
  final String? districtCode;
  final LoadStatus districtsStatus;
  final List<Region> districts;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  bool get canSubmit =>
      businessTypeId != null &&
      stateCode != null &&
      districtCode != null &&
      submitStatus != SubmitStatus.submitting;

  BusinessProfileState copyWith({
    AppLanguage? language,
    LoadStatus? optionsStatus,
    ValueGetter<ProfileOptions?>? options,
    ValueGetter<Failure?>? optionsFailure,
    ValueGetter<String?>? businessTypeId,
    ValueGetter<String?>? stateCode,
    ValueGetter<String?>? districtCode,
    LoadStatus? districtsStatus,
    List<Region>? districts,
    SubmitStatus? submitStatus,
    ValueGetter<Failure?>? submitFailure,
  }) {
    return BusinessProfileState(
      language: language ?? this.language,
      optionsStatus: optionsStatus ?? this.optionsStatus,
      options: options != null ? options() : this.options,
      optionsFailure: optionsFailure != null
          ? optionsFailure()
          : this.optionsFailure,
      businessTypeId: businessTypeId != null
          ? businessTypeId()
          : this.businessTypeId,
      stateCode: stateCode != null ? stateCode() : this.stateCode,
      districtCode: districtCode != null ? districtCode() : this.districtCode,
      districtsStatus: districtsStatus ?? this.districtsStatus,
      districts: districts ?? this.districts,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: submitFailure != null
          ? submitFailure()
          : this.submitFailure,
    );
  }

  @override
  List<Object?> get props => [
    language,
    optionsStatus,
    options,
    optionsFailure,
    businessTypeId,
    stateCode,
    districtCode,
    districtsStatus,
    districts,
    submitStatus,
    submitFailure,
  ];
}

@injectable
class BusinessProfileCubit extends Cubit<BusinessProfileState> {
  BusinessProfileCubit(
    this._getProfileOptions,
    this._getDistricts,
    this._saveBusinessProfile,
    LocaleRepository locale,
  ) : super(BusinessProfileState(language: locale.current));

  final GetProfileOptions _getProfileOptions;
  final GetDistricts _getDistricts;
  final SaveBusinessProfile _saveBusinessProfile;

  Future<void> load() async {
    emit(state.copyWith(optionsStatus: LoadStatus.loading));
    final result = await _getProfileOptions();
    emit(
      result.fold(
        (failure) => state.copyWith(
          optionsStatus: LoadStatus.failure,
          optionsFailure: () => failure,
        ),
        (options) => state.copyWith(
          optionsStatus: LoadStatus.ready,
          options: () => options,
          optionsFailure: () => null,
        ),
      ),
    );
  }

  void selectBusinessType(String id) =>
      emit(state.copyWith(businessTypeId: () => id));

  Future<void> selectState(String code) async {
    if (code == state.stateCode) return;
    emit(
      state.copyWith(
        stateCode: () => code,
        districtCode: () => null,
        districts: const [],
      ),
    );
    await _loadDistricts();
  }

  Future<void> retryDistricts() => _loadDistricts();

  void selectDistrict(String code) =>
      emit(state.copyWith(districtCode: () => code));

  void selectLanguage(AppLanguage language) =>
      emit(state.copyWith(language: language));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _saveBusinessProfile(
      BusinessProfile(
        businessTypeId: state.businessTypeId!,
        stateCode: state.stateCode!,
        districtCode: state.districtCode!,
        preferredLanguage: state.language.code,
      ),
    );
    emit(
      result.fold(
        (failure) => state.copyWith(
          submitStatus: SubmitStatus.failure,
          submitFailure: () => failure,
        ),
        (_) => state.copyWith(
          submitStatus: SubmitStatus.success,
          submitFailure: () => null,
        ),
      ),
    );
  }

  Future<void> _loadDistricts() async {
    final code = state.stateCode;
    if (code == null) return;
    emit(state.copyWith(districtsStatus: LoadStatus.loading));
    final result = await _getDistricts(code);
    // Ignore a response for a state the user has since changed.
    if (isClosed || state.stateCode != code) return;
    emit(
      result.fold(
        (_) => state.copyWith(districtsStatus: LoadStatus.failure),
        (districts) => state.copyWith(
          districtsStatus: LoadStatus.ready,
          districts: districts,
        ),
      ),
    );
  }
}
