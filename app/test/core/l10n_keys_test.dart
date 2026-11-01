import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A key written twice in an `.arb` file is not an error to the tools: the last
/// one silently wins, so a new string can replace an existing one (or never
/// show). This keeps every language file free of them.
void main() {
  final keyPattern = RegExp(r'^  "([A-Za-z0-9_@]+)"\s*:', multiLine: true);

  for (final file in Directory(
    'lib/core/l10n/arb',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
    test('${file.uri.pathSegments.last} has no key written twice', () {
      final keys = [
        for (final m in keyPattern.allMatches(file.readAsStringSync()))
          m.group(1)!,
      ];
      final seen = <String>{};
      final duplicates = {
        for (final k in keys)
          if (!seen.add(k)) k,
      };

      expect(duplicates, isEmpty);
    });
  }
}
