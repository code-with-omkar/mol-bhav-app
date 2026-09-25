import 'package:equatable/equatable.dart';

import 'mobile_number.dart';

/// An OTP sent to [mobile], awaiting verification.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.mobile,
    required this.codeLength,
    required this.resendAfter,
  });

  final MobileNumber mobile;
  final int codeLength;

  /// How long the user must wait before requesting a new code.
  final Duration resendAfter;

  @override
  List<Object?> get props => [mobile, codeLength, resendAfter];
}
