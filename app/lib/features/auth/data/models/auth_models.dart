/// `POST /auth/otp/request` → after envelope unwrap:
/// `{ expiresAtUtc, resendCooldownSeconds }`
class OtpRequestResponse {
  const OtpRequestResponse({
    required this.expiresAtUtc,
    required this.resendCooldownSeconds,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      resendCooldownSeconds: json['resendCooldownSeconds'] as int,
    );
  }

  final DateTime expiresAtUtc;
  final int resendCooldownSeconds;
}

/// `POST /auth/otp/verify` → after envelope unwrap:
/// `{ session: { userId, accessToken, ..., refreshToken, ... }, isNewUser, isOnboarded }`
class OtpVerifyResponse {
  const OtpVerifyResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isOnboarded,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>;
    return OtpVerifyResponse(
      accessToken: session['accessToken'] as String,
      refreshToken: session['refreshToken'] as String,
      isOnboarded: json['isOnboarded'] as bool,
    );
  }

  final String accessToken;
  final String refreshToken;
  final bool isOnboarded;
}
