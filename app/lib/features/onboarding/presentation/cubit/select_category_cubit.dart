import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/statuses.dart';
import '../../domain/entities/onboarding_entities.dart';
import '../../domain/usecases/onboarding_usecases.dart';

class SelectCategoryState extends Equatable {
  const SelectCategoryState({
    this.status = LoadStatus.initial,
    this.categories = const [],
    this.failure,
    this.selected = const {},
    this.submitStatus = SubmitStatus.idle,
    this.submitFailure,
  });

  final LoadStatus status;
  final List<ProcurementCategory> categories;
  final Failure? failure;
  final Set<String> selected;
  final SubmitStatus submitStatus;
  final Failure? submitFailure;

  bool get canSubmit =>
      selected.isNotEmpty && submitStatus != SubmitStatus.submitting;

  SelectCategoryState copyWith({
    LoadStatus? status,
    List<ProcurementCategory>? categories,
    Failure? failure,
    Set<String>? selected,
    SubmitStatus? submitStatus,
    Failure? submitFailure,
  }) {
    return SelectCategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      failure: failure,
      selected: selected ?? this.selected,
      submitStatus: submitStatus ?? this.submitStatus,
      submitFailure: submitFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    failure,
    selected,
    submitStatus,
    submitFailure,
  ];
}

@injectable
class SelectCategoryCubit extends Cubit<SelectCategoryState> {
  SelectCategoryCubit(this._getCategories, this._saveCategories)
    : super(const SelectCategoryState());

  final GetCategories _getCategories;
  final SaveCategories _saveCategories;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _getCategories();
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: LoadStatus.failure, failure: failure),
        (categories) =>
            state.copyWith(status: LoadStatus.ready, categories: categories),
      ),
    );
  }

  /// Adds or removes a launched category; unavailable ones are ignored.
  void toggle(String id) {
    final category = state.categories.where((c) => c.id == id).firstOrNull;
    if (category == null || !category.isAvailable) return;
    final next = {...state.selected};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selected: next, submitStatus: SubmitStatus.idle));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _saveCategories(state.selected);
    emit(
      result.fold(
        (failure) => state.copyWith(
          submitStatus: SubmitStatus.failure,
          submitFailure: failure,
        ),
        (_) => state.copyWith(submitStatus: SubmitStatus.success),
      ),
    );
  }
}
