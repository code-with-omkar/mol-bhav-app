import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/files/file_saver.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/formatters.dart';
import 'price_share_data.dart';
import 'share_price_card.dart';

/// Shares one price as a picture plus a text message.
///
/// The image is rendered by mounting [SharePriceCard] off-screen in the live
/// widget tree — it therefore inherits the app's theme, locale and already
/// loaded fonts, which is what makes Devanagari and the other Indic scripts
/// come out as text rather than boxes.
///
/// The web has no share-sheet file support worth relying on, so there the text
/// is shared and the picture is handed to the browser as a download instead.
Future<void> sharePriceCard(BuildContext context, PriceShareData data) async {
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

/// The message body: the same facts as the card, for apps that show only text.
String priceShareText(BuildContext context, PriceShareData data) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  return [
    l10n.sharePriceHeadline(data.title, data.mandiName),
    l10n.shareModalLine('${formatInr(data.modalPrice)}/${data.unitSymbol}'),
    if (data.hasRange)
      l10n.shareRange(formatInr(data.minPrice!), formatInr(data.maxPrice!)),
    l10n.priceDate(formatDayMonth(data.recordDate, locale)),
    l10n.sourceLine(data.source),
    '',
    data.link,
  ].join('\n');
}

String _fileName(PriceShareData data) {
  final slug = data.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final day = data.recordDate.toIso8601String().split('T').first;
  return 'molbhav-${slug.isEmpty ? 'price' : slug}-$day.png';
}

/// Mounts the card in an overlay, off-screen and non-interactive, long enough
/// to paint one frame and copy it out. Returns null if anything goes wrong —
/// the caller then shares text only.
Future<Uint8List?> _renderCard(
  BuildContext context,
  PriceShareData data,
) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  // google_fonts fetches on first use; capturing before they land would bake
  // in the fallback face.
  try {
    await GoogleFonts.pendingFonts();
  } on Object {
    // A font that never arrives is not a reason to drop the share.
  }
  if (!context.mounted) return null;

  final boundary = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Off-screen: laid out and painted, never seen and never tappable.
      left: -SharePriceCard.width * 2,
      top: 0,
      child: IgnorePointer(
        child: RepaintBoundary(
          key: boundary,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                decoration: TextDecoration.none,
                decorationColor: null,
              ),
              child: SharePriceCard(data: data),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Two frames: one to lay the card out, one to be sure it has painted.
    await _nextFrame();
    await _nextFrame();
    final render = boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) return null;
    final image = await render.toImage(pixelRatio: 3);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } on Object {
    return null;
  } finally {
    entry.remove();
  }
}

Future<void> _nextFrame() {
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
  return completer.future;
}
