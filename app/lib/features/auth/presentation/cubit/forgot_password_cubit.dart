import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/password_reset.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({this.sentTo, this.busy = false});

  /// The number a code was asked for; null while the number is being typed.
  final MobileNumber? sentTo;

  /// A request is in flight.
  final bool busy;

  @override
  List<Object?> get props => [sentTo, busy];
}

/// The two steps of "forgot password".
@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._repository) : super(const ForgotPasswordState());

  final PasswordResetRepository _repository;

  /// Asks for a code. Null on success (the form moves to step two).
  Future<Failure?> sendCode(MobileNumber mobile) async {
    if (state.busy) return null;
    emit(ForgotPasswordState(sentTo: state.sentTo, busy: true));
    final result = await _repository.requestCode(mobile.e164);
    if (isClosed) return null;
    switch (result) {
      case Err<void>(:final failure):
        emit(ForgotPasswordState(sentTo: state.sentTo));
        return failure;
      case Ok<void>():
        emit(ForgotPasswordState(sentTo: mobile));
        return null;
    }
  }

  /// Sets the new password. Null on success.
  Future<Failure?> reset({
    required String code,
    required String newPassword,
  }) async {
    final mobile = state.sentTo;
    if (state.busy || mobile == null) return null;
    emit(ForgotPasswordState(sentTo: mobile, busy: true));
    final result = await _repository.resetPassword(
      phoneNumber: mobile.e164,
      code: code,
      newPassword: newPassword,
    );
    if (!isClosed) emit(ForgotPasswordState(sentTo: mobile));
    return switch (result) {
      Err<void>(:final failure) => failure,
      Ok<void>() => null,
    };
  }

  /// Back to step one, to correct the number.
  void changeNumber() => emit(const ForgotPasswordState());
}
