import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/files/file_saver.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import '../../../monetization/presentation/ads/interstitial_ads.dart';
import 'price_share_data.dart';
import 'share_price_card.dart';

/// Shares one price as a picture plus a text message.
///
/// The image is rendered by mounting [SharePriceCard] off-screen in the live
/// widget tree — it therefore inherits the app's theme, locale and already
/// loaded fonts, which is what makes Devanagari and the other Indic scripts
/// come out as text rather than boxes.
///
/// On the web the browser's share sheet (Web Share API) is tried first with the
/// picture attached — Chrome on Android, Windows and macOS supports it. Only
/// when the browser cannot share files is the text shared and the picture
/// handed over as a download.
Future<void> sharePriceCard(BuildContext context, PriceShareData data) async {
  // Preload while the card renders and the share sheet is open; the ad (if
  // one is due) shows once sharing is over — a natural break, never mid-task.
  final interstitials = getIt<InterstitialAds>();
  unawaited(interstitials.warmUp());
  try {
    await _share(context, data);
  } finally {
    unawaited(interstitials.showIfDue());
  }
}

Future<void> _share(BuildContext context, PriceShareData data) async {
  final l10n = context.l10n;
  final text = priceShareText(context, data);
  final fileName = _fileName(data);
  final messenger = ScaffoldMessenger.of(context);

  final png = await _renderCard(context, data);
  if (png == null) {
    // Rendering is best-effort: a text-only share still carries the price.
    await SharePlus.instance.share(ShareParams(text: text));
    return;
  }

  if (kIsWeb) {
    if (await _tryWebShare(text, png, fileName)) return;
    await SharePlus.instance.share(ShareParams(text: text));
    final saved = await saveAndOpenFile(
      name: fileName,
      mimeType: 'image/png',
      bytes: png,
    );
    if (!saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareImageSaved)));
    }
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
      fileNameOverrides: [fileName],
    ),
  );
}

/// True when the browser's share sheet opened with the picture attached.
///
/// share_plus' own web fallbacks (download, mailto) are switched off here so a
/// browser without file sharing throws instead, and the caller's text +
/// download path runs exactly once. The web cannot report whether the user
/// actually shared, so any non-throwing return counts as handled.
Future<bool> _tryWebShare(String text, Uint8List png, String fileName) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        downloadFallbackEnabled: false,
        mailToFallbackEnabled: false,
      ),
    );
    return true;
  } on Object {
    return false;
  }
}

/// The message that accompanies the picture (and stands alone when the picture
/// cannot be produced).
String priceShareText(BuildContext context, PriceShareData data) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  final lines = <String>[
    l10n.sharePriceHeadline(data.title, data.mandiName),
    l10n.shareModalLine('${formatInr(data.modalPrice)}/${data.unitSymbol}'),
    if (data.hasRange)
      l10n.shareRange(formatInr(data.minPrice!), formatInr(data.maxPrice!)),
    l10n.priceDate(formatDayMonth(data.recordDate, locale)),
    l10n.sourceLine(data.source),
    data.link,
  ];
  return lines.join('\n');
}

String _fileName(PriceShareData data) {
  final slug = data.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'molbhav-${slug.isEmpty ? 'price' : slug}.png';
}

/// Mounts [SharePriceCard] off-screen, captures it and removes it again.
/// Returns null when anything in the pipeline fails.
Future<Uint8List?> _renderCard(
  BuildContext context,
  PriceShareData data,
) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -(SharePriceCard.width * 3),
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: boundaryKey,
          child: SharePriceCard(data: data),
        ),
      ),
    ),
  );

  try {
    overlay.insert(entry);
    // Let the card lay out, then wait for any Google fonts still in flight so
    // the capture does not fall back to boxes.
    await WidgetsBinding.instance.endOfFrame;
    await GoogleFonts.pendingFonts();
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  } on Object {
    return null;
  } finally {
    entry.remove();
    entry.dispose();
  }
}
