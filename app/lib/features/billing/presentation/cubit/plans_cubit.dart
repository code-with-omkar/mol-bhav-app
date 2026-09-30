import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/billing.dart';

sealed class PlansState extends Equatable {
  const PlansState();

  @override
  List<Object?> get props => [];
}

final class PlansInitial extends PlansState {
  const PlansInitial();
}

final class PlansLoading extends PlansState {
  const PlansLoading();
}

final class PlansLoaded extends PlansState {
  const PlansLoaded({
    required this.plans,
    required this.cycle,
    this.selectedPlan,
  });

  final List<Plan> plans;
  final BillingCycle cycle;
  final Plan? selectedPlan;

  List<Plan> get visiblePlans => [
    for (final p in plans)
      if (p.cycle == cycle) p,
  ];

  /// Whole percent a yearly plan saves over twelve months of its monthly twin
  /// (same name); `null` when there is no pair or no saving.
  int? get yearlySavingPercent {
    for (final yearly in plans.where((p) => p.cycle == BillingCycle.yearly)) {
      for (final monthly in plans.where(
        (p) => p.cycle == BillingCycle.monthly && p.name == yearly.name,
      )) {
        final twelve = monthly.pricePaise * 12;
        if (twelve <= 0) continue;
        final percent = ((twelve - yearly.pricePaise) * 100 / twelve).floor();
        return percent > 0 ? percent : null;
      }
    }
    return null;
  }

  PlansLoaded copyWith({
    List<Plan>? plans,
    BillingCycle? cycle,
    Plan? selectedPlan,
  }) => PlansLoaded(
    plans: plans ?? this.plans,
    cycle: cycle ?? this.cycle,
    selectedPlan: selectedPlan ?? this.selectedPlan,
  );

  @override
  List<Object?> get props => [plans, cycle, selectedPlan];
}

final class PlansError extends PlansState {
  const PlansError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@injectable
class PlansCubit extends Cubit<PlansState> {
  PlansCubit(this._repository) : super(const PlansInitial());

  final BillingRepository _repository;
  StreamSubscription<Result<List<Plan>>>? _sub;

  Future<void> load() async {
    await _sub?.cancel();
    if (state is! PlansLoaded) emit(const PlansLoading());
    final done = Completer<void>();
    _sub = _repository.watchPlans().listen((result) {
      switch (result) {
        case Ok(:final value):
          final current = state;
          emit(
            current is PlansLoaded
                ? current.copyWith(plans: value)
                : PlansLoaded(plans: value, cycle: BillingCycle.monthly),
          );
        case Err(:final failure):
          if (state is! PlansLoaded) emit(PlansError(failure));
      }
    }, onDone: done.complete);
    return done.future;
  }

  void selectPlan(Plan plan) {
    final current = state;
    if (current is PlansLoaded) emit(current.copyWith(selectedPlan: plan));
  }

  void toggleBillingCycle() {
    final current = state;
    if (current is! PlansLoaded) return;
    emit(
      PlansLoaded(
        plans: current.plans,
        cycle: current.cycle == BillingCycle.monthly
            ? BillingCycle.yearly
            : BillingCycle.monthly,
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
