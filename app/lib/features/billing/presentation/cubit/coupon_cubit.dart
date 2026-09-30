import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/billing.dart';

sealed class CouponState extends Equatable {
  const CouponState();

  @override
  List<Object?> get props => [];
}

final class CouponInitial extends CouponState {
  const CouponInitial();
}

final class CouponValidating extends CouponState {
  const CouponValidating(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class CouponValid extends CouponState {
  const CouponValid(this.code, this.validation);

  final String code;
  final CouponValidation validation;

  @override
  List<Object?> get props => [code, validation];
}

/// [failure] is set when the check itself failed (e.g. offline); otherwise
/// the code is simply not usable for this plan.
final class CouponInvalid extends CouponState {
  const CouponInvalid(this.code, {this.failure});

  final String code;
  final Failure? failure;

  @override
  List<Object?> get props => [code, failure];
}

/// Validates the coupon field as the user types: one request per pause in
/// typing, and a slow answer for an older input is dropped.
@injectable
class CouponCubit extends Cubit<CouponState> {
  CouponCubit(this._repository) : super(const CouponInitial());

  final BillingRepository _repository;

  @visibleForTesting
  Duration debounce = const Duration(milliseconds: 800);

  Timer? _timer;
  String _latest = '';

  void onCodeChanged(String input, String planCode) {
    _timer?.cancel();
    final code = input.trim().toUpperCase();
    _latest = code;
    if (code.isEmpty) {
      emit(const CouponInitial());
      return;
    }
    _timer = Timer(debounce, () => _validate(code, planCode));
  }

  void clear() {
    _timer?.cancel();
    _latest = '';
    emit(const CouponInitial());
  }

  Future<void> _validate(String code, String planCode) async {
    emit(CouponValidating(code));
    final result = await _repository.validateCoupon(code, planCode);
    if (isClosed || code != _latest) return;
    emit(switch (result) {
      Ok(value: final v) when v.isValid => CouponValid(code, v),
      Ok() => CouponInvalid(code),
      Err(:final failure) => CouponInvalid(code, failure: failure),
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
