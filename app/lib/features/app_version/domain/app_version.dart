import 'package:equatable/equatable.dart';

import '../../../core/error/result.dart';

/// The oldest app version allowed to run (`GET /app-version`).
class AppVersionPolicy extends Equatable {
  const AppVersionPolicy({this.minimumVersion, this.updateUrl});

  /// `major.minor.patch`; null when every version may run.
  final String? minimumVersion;

  /// Where to update from (a store page); null when none is set.
  final String? updateUrl;

  @override
  List<Object?> get props => [minimumVersion, updateUrl];
}

/// `1.2.3+4` / `1.2` / `1.2.3-beta` as three numbers; null when it is not a
/// dotted version at all. A build number or suffix is ignored.
List<int>? parseVersion(String version) {
  final core = version.trim().split(RegExp('[+-]')).first;
  final parts = core.split('.');
  if (parts.isEmpty || parts.length > 3) return null;
  final numbers = <int>[];
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null || n < 0) return null;
    numbers.add(n);
  }
  while (numbers.length < 3) {
    numbers.add(0);
  }
  return numbers;
}

/// [installed] is older than [minimum]. Anything that cannot be read is never
/// older, so a bad value never locks users out.
bool isOlderThan(String installed, String minimum) {
  final a = parseVersion(installed);
  final b = parseVersion(minimum);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}

/// The version of this installed build.
abstract interface class InstalledVersion {
  Future<String?> get();
}

abstract interface class AppVersionRepository {
  Future<Result<AppVersionPolicy>> get();

  /// Admin: sets the minimum version and update link (empty clears them).
  Future<Result<void>> save(AppVersionPolicy policy);
}
