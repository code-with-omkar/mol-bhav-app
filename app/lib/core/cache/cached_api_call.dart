import '../error/failure.dart';
import '../error/result.dart';
import '../network/api_call.dart';
import 'response_cache.dart';

/// Network-first fetch with an offline fallback.
///
/// A successful response is stored under [key] and parsed. When the call
/// fails with a [NetworkFailure], the last stored response for [key] is
/// parsed instead. Price screens show their data timestamp, so cached data
/// reads as stale. Other failures are returned unchanged.
Future<Result<T>> runCachedApiCall<T>({
  required ResponseCache cache,
  required String key,
  required Future<Object> Function() fetch,
  required T Function(Object json) parse,
}) async {
  final live = await runApiCall(() async {
    final json = await fetch();
    await cache.write(key, json);
    return parse(json);
  });
  if (live case Err(failure: NetworkFailure())) {
    final cached = cache.read(key);
    if (cached != null) {
      final offline = await runApiCall(() async => parse(cached.data));
      // A cached body that no longer parses is ignored.
      if (offline is Ok<T>) return offline;
    }
  }
  return live;
}
