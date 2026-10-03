import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/mobile_number.dart';
import '../../domain/usecases/password_auth.dart';

enum PasswordLoginMode { signIn, register }

enum PasswordLoginStatus { editing, submitting, success, failure }

/// Client-side password problems, shown under the field.
enum PasswordIssue { empty, tooWeak, mismatch }

class PasswordLoginState extends Equatable {
  const PasswordLoginState({
    this.mode = PasswordLoginMode.signIn,
    this.mobile = '',
    this.password = '',
    this.confirmPassword = '',
    this.status = PasswordLoginStatus.editing,
    this.showInvalidNumber = false,
    this.passwordIssue,
    this.failure,
    this.session,
  });

  /// Mirrors the server policy (8–128 characters, a letter and a digit).
  static const minLength = 8;
  static const maxLength = 128;

  final PasswordLoginMode mode;
  final String mobile;
  final String password;
  final String confirmPassword;
  final PasswordLoginStatus status;
  final bool showInvalidNumber;
  final PasswordIssue? passwordIssue;
  final Failure? failure;
  final AuthSession? session;

  bool get isRegister => mode == PasswordLoginMode.register;

  PasswordLoginState _editing({
    PasswordLoginMode? mode,
    String? mobile,
    String? password,
    String? confirmPassword,
  }) => PasswordLoginState(
    mode: mode ?? this.mode,
    mobile: mobile ?? this.mobile,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
  );

  @override
  List<Object?> get props => [
    mode,
    mobile,
    password,
    confirmPassword,
    status,
    showInvalidNumber,
    passwordIssue,
    failure,
    session,
  ];
}

/// Mobile number + password sign-in and "create account" (no SMS cost).
class PasswordLoginCubit extends Cubit<PasswordLoginState> {
  PasswordLoginCubit(this._login, this._register)
    : super(const PasswordLoginState());

  final LoginWithPassword _login;
  final RegisterWithPassword _register;

  void mobileChanged(String value) => emit(state._editing(mobile: value));

  void passwordChanged(String value) => emit(state._editing(password: value));

  void confirmPasswordChanged(String value) =>
      emit(state._editing(confirmPassword: value));

  /// Switches between "log in" and "create account", keeping what was typed.
  void toggleMode() => emit(
    PasswordLoginState(
      mode: state.isRegister
          ? PasswordLoginMode.signIn
          : PasswordLoginMode.register,
      mobile: state.mobile,
      password: state.password,
    ),
  );

  Future<void> submit() async {
    if (state.status == PasswordLoginStatus.submitting) return;

    final mobile = MobileNumber.tryParse(state.mobile);
    final issue = _passwordIssue();
    if (mobile == null || issue != null) {
      emit(
        PasswordLoginState(
          mode: state.mode,
          mobile: state.mobile,
          password: state.password,
          confirmPassword: state.confirmPassword,
          showInvalidNumber: mobile == null,
          passwordIssue: issue,
        ),
      );
      return;
    }

    final submitted = state._editing();
    emit(
      PasswordLoginState(
        mode: submitted.mode,
        mobile: submitted.mobile,
        password: submitted.password,
        confirmPassword: submitted.confirmPassword,
        status: PasswordLoginStatus.submitting,
      ),
    );

    final result = submitted.isRegister
        ? await _register(mobile, submitted.password)
        : await _login(mobile, submitted.password);

    emit(
      result.fold(
        (failure) => PasswordLoginState(
          mode: submitted.mode,
          mobile: submitted.mobile,
          password: submitted.password,
          confirmPassword: submitted.confirmPassword,
          status: PasswordLoginStatus.failure,
          failure: failure,
        ),
        (session) => PasswordLoginState(
          mode: submitted.mode,
          mobile: submitted.mobile,
          status: PasswordLoginStatus.success,
          session: session,
        ),
      ),
    );
  }

  PasswordIssue? _passwordIssue() {
    final password = state.password;
    if (!state.isRegister) {
      return password.isEmpty ? PasswordIssue.empty : null;
    }
    final strong =
        password.length >= PasswordLoginState.minLength &&
        password.length <= PasswordLoginState.maxLength &&
        password.contains(RegExp(r'\p{L}', unicode: true)) &&
        password.contains(RegExp(r'\d'));
    if (!strong) return PasswordIssue.tooWeak;
    if (state.confirmPassword != password) return PasswordIssue.mismatch;
    return null;
  }
}
