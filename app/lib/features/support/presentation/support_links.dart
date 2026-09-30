import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/support.dart';

/// Hands a support channel to the platform: WhatsApp, the dialler, or the
/// mail client. Returns false when nothing on the device can open it, so the
/// caller can say so rather than leave the tap looking ignored.
abstract final class SupportLinks {
  static Future<bool> whatsApp(SupportContact contact, String message) => _open(
    Uri.https('wa.me', '/${contact.whatsAppNumber}', {'text': message}),
  );

  /// `tel:` keeps the digits and a leading `+` only — the dialler rejects spaces.
  static Future<bool> call(SupportContact contact) => _open(
    Uri(scheme: 'tel', path: contact.phone.replaceAll(RegExp(r'[^0-9+]'), '')),
  );

  /// The body carries the app version and the masked phone so support can
  /// find the account without the user having to quote anything.
  static Future<bool> email(
    SupportContact contact, {
    required String subject,
    required String bodyIntro,
    required String versionLabel,
    required String accountLabel,
    String? phoneMasked,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final body = [
      bodyIntro,
      '',
      '---',
      '$versionLabel: ${info.version} (${info.buildNumber})',
      if (phoneMasked != null && phoneMasked.isNotEmpty)
        '$accountLabel: $phoneMasked',
    ].join('\n');

    return _open(
      Uri(
        scheme: 'mailto',
        path: contact.email,
        queryParameters: {'subject': subject, 'body': body},
      ),
    );
  }

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // No handler registered (a bare emulator, a locked-down browser).
      return false;
    }
  }
}
