import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/login_methods.dart';
import '../../domain/usecases/password_auth.dart';

class LoginMethodsState extends Equatable {
  const LoginMethodsState({this.methods, this.loading = true});

  /// Null until the first answer (or the fallback) arrives.
  final LoginMethods? methods;
  final bool loading;

  @override
  List<Object?> get props => [methods, loading];
}

/// Asks the server which sign-in options to show on the login screen.
class LoginMethodsCubit extends Cubit<LoginMethodsState> {
  LoginMethodsCubit(this._getLoginMethods) : super(const LoginMethodsState());

  final GetLoginMethods _getLoginMethods;

  Future<void> load() async {
    emit(LoginMethodsState(methods: state.methods));
    final result = await _getLoginMethods();
    emit(
      LoginMethodsState(
        // Unreachable server: show password login, which needs no SMS; the
        // submit itself will surface the network error.
        methods: result.fold((_) => LoginMethods.fallback, (m) => m),
        loading: false,
      ),
    );
  }
}
