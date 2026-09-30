import 'dart:typed_data';

import 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as platform;

/// Hands a downloaded file to the user: a browser download on the web; on
/// mobile it is written to the app's documents folder and opened in the
/// system viewer. Returns `false` when nothing could open it.
Future<bool> saveAndOpenFile({
  required String name,
  required String mimeType,
  required Uint8List bytes,
}) => platform.saveAndOpen(name: name, mimeType: mimeType, bytes: bytes);
