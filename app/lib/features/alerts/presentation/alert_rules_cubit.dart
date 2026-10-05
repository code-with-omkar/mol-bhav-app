import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failure.dart';
import '../domain/alerts.dart';

sealed class AlertRulesState extends Equatable {
  const AlertRulesState();
}

class AlertRulesLoading extends AlertRulesState {
  const AlertRulesLoading();

  @override
  List<Object?> get props => [];
}

class AlertRulesLoaded extends AlertRulesState {
  const AlertRulesLoaded(this.rules);

  final List<AlertRule> rules;

  @override
  List<Object?> get props => [rules];
}

class AlertRulesError extends AlertRulesState {
  const AlertRulesError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@injectable
class AlertRulesCubit extends Cubit<AlertRulesState> {
  AlertRulesCubit(this._repository) : super(const AlertRulesLoading());

  final AlertsRepository _repository;

  Future<void> load() async {
    emit(const AlertRulesLoading());
    await _watch();
  }

  Future<void> deleteRule(String id) async {
    final result = await _repository.deleteAlertRule(id);
    if (isClosed) return;
    result.fold((_) {}, (_) => _reload());
  }

  Future<void> updateRule(String id, UpdateAlertRuleRequest req) async {
    final result = await _repository.updateAlertRule(id, req);
    if (isClosed) return;
    result.fold((_) {}, (_) => _reload());
  }

  Future<void> _reload() => _watch();

  /// Saved rules first, then live (the repository drops the saved copy after
  /// every change, so a reload after edit/delete is always live).
  Future<void> _watch() async {
    await for (final result in _repository.watchAlertRules()) {
      if (isClosed) return;
      emit(result.fold(AlertRulesError.new, AlertRulesLoaded.new));
    }
  }
}
