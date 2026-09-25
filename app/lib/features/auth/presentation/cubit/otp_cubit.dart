import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/utils/countdown.dart';
import '../../domain/auth_failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/verify_otp.dart';

enum OtpStatus { editing, verifying, verified, resending, resent, failure }

class OtpState extends Equatable {
  const OtpState({
    required this.challenge,
    required this.secondsLeft,
    this.code = '',
    this.status = OtpStatus.editing,
    this.failure,
    this.session,
  });

  final OtpChallenge challenge;
  final int secondsLeft;
  final String code;
  final OtpStatus status;
  final Failure? failure;
  final AuthSession? session;

  bool get isComplete => code.length == challenge.codeLength;
  bool get isBusy =>
      status == OtpStatus.verifying || status == OtpStatus.resending;
  bool get canResend => secondsLeft == 0 && !isBusy;
  bool get isCodeInvalid => failure is InvalidOtpFailure;

  OtpState copyWith({
    OtpChallenge? challenge,
    int? secondsLeft,
    String? code,
    required OtpStatus status,
    Failure? failure,
    AuthSession? session,
  }) {
    return OtpState(
      challenge: challenge ?? this.challenge,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      code: code ?? this.code,
      status: status,
      failure: failure,
      session: session,
    );
  }

  @override
  List<Object?> get props => [
    challenge,
    secondsLeft,
    code,
    status,
    failure,
    session,
  ];
}

@injectable
class OtpCubit extends Cubit<OtpState> {
  OtpCubit(
    @factoryParam OtpChallenge challenge,
    this._verifyOtp,
    this._requestOtp,
    this._countdown,
  ) : super(
        OtpState(
          challenge: challenge,
          secondsLeft: challenge.resendAfter.inSeconds,
        ),
      ) {
    _startCountdown();
  }

  final VerifyOtp _verifyOtp;
  final RequestOtp _requestOtp;
  final Countdown _countdown;
  StreamSubscription<int>? _ticker;

  void codeChanged(String code) {
    if (code == state.code) return;
    emit(state.copyWith(code: code, status: OtpStatus.editing));
  }

  Future<void> verify() async {
    if (!state.isComplete || state.isBusy) return;
    emit(state.copyWith(status: OtpStatus.verifying));
    final result = await _verifyOtp(
      mobile: state.challenge.mobile,
      code: state.code,
    );
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: OtpStatus.failure, failure: failure),
        (session) =>
            state.copyWith(status: OtpStatus.verified, session: session),
      ),
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    emit(state.copyWith(code: '', status: OtpStatus.resending));
    final result = await _requestOtp(state.challenge.mobile);
    result.fold(
      (failure) =>
          emit(state.copyWith(status: OtpStatus.failure, failure: failure)),
      (challenge) {
        emit(
          state.copyWith(
            challenge: challenge,
            secondsLeft: challenge.resendAfter.inSeconds,
            status: OtpStatus.resent,
          ),
        );
        _startCountdown();
      },
    );
  }

  void _startCountdown() {
    _ticker?.cancel();
    _ticker = _countdown
        .start(state.secondsLeft)
        .listen(
          (left) => emit(
            state.copyWith(
              secondsLeft: left,
              status: state.status,
              failure: state.failure,
              session: state.session,
            ),
          ),
        );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
