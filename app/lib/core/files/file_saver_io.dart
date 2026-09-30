import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> saveAndOpen({
  required String name,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  // Names come from the server's Content-Disposition; keep them to one
  // path segment.
  final safe = name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
  final file = File('${dir.path}${Platform.pathSeparator}$safe');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFilex.open(file.path, type: mimeType);
  return result.type == ResultType.done;
}
