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

/// `POST /auth/otp/verify`, `/auth/password/login` and `/auth/password/register`
/// all return the same login shape → after envelope unwrap:
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

/// `GET /auth/methods` → after envelope unwrap: `{ otp, password }`
class LoginMethodsResponse {
  const LoginMethodsResponse({required this.otp, required this.password});

  factory LoginMethodsResponse.fromJson(Map<String, dynamic> json) {
    return LoginMethodsResponse(
      otp: json['otp'] as bool? ?? false,
      password: json['password'] as bool? ?? false,
    );
  }

  final bool otp;
  final bool password;
}
