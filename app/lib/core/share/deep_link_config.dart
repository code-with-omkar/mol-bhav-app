import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Link building for shares and invites, configured at build time:
/// `flutter run --dart-define=DEEP_LINK_BASE=https://app.jagtech.in`.
///
/// When [base] is empty — the default, until the domain and its
/// `.well-known` files exist — nothing is broken: shares carry the Play Store
/// link instead and [isEnabled] is false, so the app registers no deep-link
/// route it cannot honour.
abstract final class DeepLinkConfig {
  static const base = String.fromEnvironment('DEEP_LINK_BASE');

  /// Where an invite sends someone who does not have the app yet.
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.molbhav.mol_bhav';

  static bool get isEnabled => base.isNotEmpty;

  /// `{base}/p/{productId}?mandi={mandiId}` — the shape the Android
  /// intent-filter and the Apple site association are cut for. Falls back to
  /// the store link while deep linking is off, so a shared card is never
  /// sent with a dead URL.
  static String productLink(String productId, {String? mandiId}) {
    if (!isEnabled) return playStoreUrl;
    return Uri.parse(base)
        .replace(path: '/p/$productId', queryParameters: {'mandi': ?mandiId})
        .toString();
  }

  /// Play Store link tagged with a short, stable digest of the inviter's id.
  /// A raw user id would be public in every forwarded message; twelve hex
  /// characters of SHA-256 are enough to group installs later without
  /// identifying anyone from the link alone.
  static String inviteLink({String? userId}) => Uri.parse(playStoreUrl)
      .replace(
        queryParameters: {
          'id': 'com.molbhav.mol_bhav',
          'ref': ?refCode(userId),
        },
      )
      .toString();

  /// `null` when there is no signed-in user to attribute the invite to.
  static String? refCode(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    return sha256.convert(utf8.encode(userId)).toString().substring(0, 12);
  }
}
