import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/auth_failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/usecases/password_auth.dart';

enum GoogleLoginStatus { idle, submitting, needsPhone, success, failure }

class GoogleLoginState extends Equatable {
  const GoogleLoginState({
    this.status = GoogleLoginStatus.idle,
    this.idToken,
    this.showInvalidNumber = false,
    this.failure,
    this.session,
  });

  final GoogleLoginStatus status;

  /// Kept while asking for the mobile number of a new account; Google ID
  /// tokens stay valid for about an hour.
  final String? idToken;
  final bool showInvalidNumber;
  final Failure? failure;
  final AuthSession? session;

  bool get isBusy => status == GoogleLoginStatus.submitting;

  @override
  List<Object?> get props => [
    status,
    idToken,
    showInvalidNumber,
    failure,
    session,
  ];
}

/// "Continue with Google": a linked Google account signs straight in; a new
/// one is asked for its mobile number once (still the account's identity).
class GoogleLoginCubit extends Cubit<GoogleLoginState> {
  GoogleLoginCubit(this._login) : super(const GoogleLoginState());

  final LoginWithGoogle _login;

  /// A token from Google Sign-In.
  Future<void> signIn(String idToken) async {
    if (state.isBusy) return;
    emit(
      GoogleLoginState(status: GoogleLoginStatus.submitting, idToken: idToken),
    );
    final result = await _login(idToken);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => failure is GooglePhoneRequiredFailure
            ? GoogleLoginState(
                status: GoogleLoginStatus.needsPhone,
                idToken: idToken,
              )
            : GoogleLoginState(
                status: GoogleLoginStatus.failure,
                failure: failure,
              ),
        (session) => GoogleLoginState(
          status: GoogleLoginStatus.success,
          session: session,
        ),
      ),
    );
  }

  /// Second step for a new Google account.
  Future<void> submitPhone(String input) async {
    final idToken = state.idToken;
    if (idToken == null || state.isBusy) return;

    final mobile = MobileNumber.tryParse(input);
    if (mobile == null) {
      emit(
        GoogleLoginState(
          status: GoogleLoginStatus.needsPhone,
          idToken: idToken,
          showInvalidNumber: true,
        ),
      );
      return;
    }

    emit(
      GoogleLoginState(status: GoogleLoginStatus.submitting, idToken: idToken),
    );
    final result = await _login(idToken, mobile: mobile);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => GoogleLoginState(
          status: GoogleLoginStatus.failure,
          failure: failure,
        ),
        (session) => GoogleLoginState(
          status: GoogleLoginStatus.success,
          session: session,
        ),
      ),
    );
  }

  /// The mobile step was dismissed.
  void cancel() => emit(const GoogleLoginState());

  /// Google Sign-In itself failed on the device.
  void deviceSignInFailed() => emit(
    const GoogleLoginState(
      status: GoogleLoginStatus.failure,
      failure: GoogleTokenInvalidFailure(),
    ),
  );
}
