import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/mobile_number.dart';
import '../entities/otp_challenge.dart';
import '../repositories/auth_repository.dart';

@injectable
class RequestOtp {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  Future<Result<OtpChallenge>> call(MobileNumber mobile) =>
      _repository.requestOtp(mobile);
}
