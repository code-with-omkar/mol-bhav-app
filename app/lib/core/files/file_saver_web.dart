import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> saveAndOpen({
  required String name,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Revoke after the click has been handled, or some browsers cancel it.
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
  return true;
}
