import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/storage/saved_credentials_store.dart';
import '../../domain/auth_failures.dart';
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
    this.savePassword = true,
    this.canSavePassword = false,
    this.prefillSeq = 0,
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

  /// The "Save password" switch — on by default.
  final bool savePassword;

  /// False on web and when no store is wired: the switch is hidden.
  final bool canSavePassword;

  /// Bumps when a saved login is loaded, so the fields copy it once.
  final int prefillSeq;

  bool get isRegister => mode == PasswordLoginMode.register;

  /// A fresh state for [status], keeping the form, the switch and the prefill
  /// counter; error flags and results reset unless passed.
  PasswordLoginState _next({
    PasswordLoginMode? mode,
    String? mobile,
    String? password,
    String? confirmPassword,
    PasswordLoginStatus status = PasswordLoginStatus.editing,
    bool showInvalidNumber = false,
    PasswordIssue? passwordIssue,
    Failure? failure,
    AuthSession? session,
    bool? savePassword,
    bool? canSavePassword,
    int? prefillSeq,
  }) => PasswordLoginState(
    mode: mode ?? this.mode,
    mobile: mobile ?? this.mobile,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    status: status,
    showInvalidNumber: showInvalidNumber,
    passwordIssue: passwordIssue,
    failure: failure,
    session: session,
    savePassword: savePassword ?? this.savePassword,
    canSavePassword: canSavePassword ?? this.canSavePassword,
    prefillSeq: prefillSeq ?? this.prefillSeq,
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
    savePassword,
    canSavePassword,
    prefillSeq,
  ];
}

/// Mobile number + password sign-in and "create account" (no SMS cost), with
/// an optional saved login ([SavedCredentialsStore], Android/iOS).
class PasswordLoginCubit extends Cubit<PasswordLoginState> {
  PasswordLoginCubit(
    this._login,
    this._register, {
    SavedCredentialsStore? savedCredentials,
  }) : _saved = savedCredentials,
       super(const PasswordLoginState());

  final LoginWithPassword _login;
  final RegisterWithPassword _register;
  final SavedCredentialsStore? _saved;

  /// Shows the switch where saving is supported and prefills a saved login.
  Future<void> loadSaved() async {
    final store = _saved;
    if (store == null || !store.isSupported) return;

    final enabled = await store.readEnabled();
    final saved = enabled ? await store.read() : null;
    if (isClosed) return;

    // Never overwrite what the user already started typing.
    final untouched = state.mobile.isEmpty && state.password.isEmpty;
    emit(
      state._next(
        status: state.status,
        canSavePassword: true,
        savePassword: enabled,
        mobile: saved != null && untouched ? saved.mobileDigits : null,
        password: saved != null && untouched ? saved.password : null,
        prefillSeq: saved != null && untouched
            ? state.prefillSeq + 1
            : state.prefillSeq,
      ),
    );
  }

  void mobileChanged(String value) => emit(state._next(mobile: value));

  void passwordChanged(String value) => emit(state._next(password: value));

  void confirmPasswordChanged(String value) =>
      emit(state._next(confirmPassword: value));

  /// Switching off forgets the saved login at once; switching on saves on the
  /// next successful sign-in.
  Future<void> savePasswordChanged(bool value) async {
    emit(state._next(status: state.status, savePassword: value));
    await _saved?.setEnabled(value);
  }

  /// Switches between "log in" and "create account", keeping what was typed.
  void toggleMode() => emit(
    state._next(
      mode: state.isRegister
          ? PasswordLoginMode.signIn
          : PasswordLoginMode.register,
      confirmPassword: '',
    ),
  );

  Future<void> submit() async {
    if (state.status == PasswordLoginStatus.submitting) return;

    final mobile = MobileNumber.tryParse(state.mobile);
    final issue = _passwordIssue();
    if (mobile == null || issue != null) {
      emit(
        state._next(showInvalidNumber: mobile == null, passwordIssue: issue),
      );
      return;
    }

    final submitted = state._next(status: PasswordLoginStatus.submitting);
    emit(submitted);

    final result = submitted.isRegister
        ? await _register(mobile, submitted.password)
        : await _login(mobile, submitted.password);

    await result.fold(
      (failure) async {
        // A saved password that the server now rejects (changed elsewhere)
        // must not be offered again.
        if (failure is InvalidCredentialsFailure && !submitted.isRegister) {
          await _forgetIfSaved(mobile, submitted.password);
        }
      },
      (_) async {
        if (submitted.canSavePassword && submitted.savePassword) {
          await _saved?.save(
            SavedCredentials(
              mobileDigits: mobile.digits,
              password: submitted.password,
            ),
          );
        }
      },
    );
    if (isClosed) return;

    emit(
      result.fold(
        (failure) => submitted._next(
          status: PasswordLoginStatus.failure,
          failure: failure,
        ),
        (session) => submitted._next(
          password: '',
          confirmPassword: '',
          status: PasswordLoginStatus.success,
          session: session,
        ),
      ),
    );
  }

  Future<void> _forgetIfSaved(MobileNumber mobile, String password) async {
    final store = _saved;
    if (store == null) return;
    final saved = await store.read();
    if (saved != null &&
        saved.mobileDigits == mobile.digits &&
        saved.password == password) {
      await store.forget();
    }
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
