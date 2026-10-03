import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/login_methods.dart';
import '../entities/mobile_number.dart';
import '../repositories/auth_repository.dart';

@injectable
class GetLoginMethods {
  const GetLoginMethods(this._repository);

  final AuthRepository _repository;

  Future<Result<LoginMethods>> call() => _repository.getLoginMethods();
}

@injectable
class LoginWithPassword {
  const LoginWithPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call(MobileNumber mobile, String password) =>
      _repository.loginWithPassword(mobile: mobile, password: password);
}

@injectable
class RegisterWithPassword {
  const RegisterWithPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call(MobileNumber mobile, String password) =>
      _repository.registerWithPassword(mobile: mobile, password: password);
}
