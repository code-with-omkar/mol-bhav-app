import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/mobile_number.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required MobileNumber mobile,
    required String code,
  }) => _repository.verifyOtp(mobile: mobile, code: code);
}
