import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/request_otp.dart';

enum LoginStatus { editing, submitting, codeSent, failure }

class LoginState extends Equatable {
  const LoginState({
    this.input = '',
    this.status = LoginStatus.editing,
    this.showInvalidNumber = false,
    this.failure,
    this.challenge,
  });

  final String input;
  final LoginStatus status;

  /// Set after a submit with an invalid number; cleared on edit.
  final bool showInvalidNumber;
  final Failure? failure;
  final OtpChallenge? challenge;

  @override
  List<Object?> get props => [
    input,
    status,
    showInvalidNumber,
    failure,
    challenge,
  ];
}

@injectable
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._requestOtp) : super(const LoginState());

  final RequestOtp _requestOtp;

  void mobileChanged(String input) => emit(LoginState(input: input));

  Future<void> submit() async {
    if (state.status == LoginStatus.submitting) return;
    final mobile = MobileNumber.tryParse(state.input);
    if (mobile == null) {
      emit(LoginState(input: state.input, showInvalidNumber: true));
      return;
    }
    emit(LoginState(input: state.input, status: LoginStatus.submitting));
    final result = await _requestOtp(mobile);
    emit(
      result.fold(
        (failure) => LoginState(
          input: state.input,
          status: LoginStatus.failure,
          failure: failure,
        ),
        (challenge) => LoginState(
          input: state.input,
          status: LoginStatus.codeSent,
          challenge: challenge,
        ),
      ),
    );
  }
}
