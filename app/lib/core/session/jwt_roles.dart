import 'dart:convert';

/// Whether the access token [jwt] carries [role] (the API puts it in the
/// `role` claim, a string or a list). Reads the payload only — it is a UI hint
/// for which screens to show; the API still enforces every admin endpoint.
bool tokenHasRole(String? jwt, String role) {
  if (jwt == null) return false;
  final parts = jwt.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    // The API issues lower-case role names (`admin`), so compare ignoring case.
    bool same(Object? r) =>
        r is String && r.toLowerCase() == role.toLowerCase();
    return switch (payload['role']) {
      final String r => same(r),
      final List<dynamic> rs => rs.any(same),
      _ => false,
    };
  } on Object {
    return false;
  }
}
