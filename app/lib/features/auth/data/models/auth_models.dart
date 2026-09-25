/// Response of `POST /auth/otp/request`.
///
/// ```json
/// { "otpLength": 6, "resendAfterSeconds": 30 }
/// ```
class OtpRequestResponse {
  const OtpRequestResponse({
    required this.otpLength,
    required this.resendAfterSeconds,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      otpLength: json['otpLength'] as int,
      resendAfterSeconds: json['resendAfterSeconds'] as int,
    );
  }

  final int otpLength;
  final int resendAfterSeconds;
}

/// Response of `POST /auth/otp/verify`.
///
/// ```json
/// { "accessToken": "…", "refreshToken": "…", "isOnboarded": false }
/// ```
class OtpVerifyResponse {
  const OtpVerifyResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isOnboarded,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isOnboarded: json['isOnboarded'] as bool,
    );
  }

  final String accessToken;
  final String refreshToken;
  final bool isOnboarded;
}
