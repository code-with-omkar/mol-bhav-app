import '../error/failure.dart';
import '../error/result.dart';
import '../network/api_call.dart';
import 'response_cache.dart';

/// How long reference data (categories, units, states, districts) is served
/// from the cache without asking the API again.
const referenceDataTtl = Duration(hours: 24);

/// Network-first fetch with an offline fallback.
///
/// A successful response is stored under [key] and parsed. When the call
/// fails with a [NetworkFailure], the last stored response for [key] is
/// parsed instead. Price screens show their data timestamp, so cached data
/// reads as stale. Other failures are returned unchanged.
///
/// With [ttl], a cached response younger than [ttl] is returned without a
/// network call.
Future<Result<T>> runCachedApiCall<T>({
  required ResponseCache cache,
  required String key,
  required Future<Object> Function() fetch,
  required T Function(Object json) parse,
  Duration? ttl,
}) async {
  final cached = cache.read(key);
  if (ttl != null && cached != null && _isFresh(cached, ttl)) {
    final fresh = await _parseCached(cached, parse);
    if (fresh != null) return fresh;
  }
  final live = await _fetchLive(cache, key, fetch, parse);
  if (live case Err(failure: NetworkFailure())) {
    if (cached != null) return await _parseCached(cached, parse) ?? live;
  }
  return live;
}

/// Stale-while-revalidate.
///
/// 1. Emits the cached value for [key] at once, when there is one.
/// 2. Fetches live, stores it and emits it — unless [ttl] is given and the
///    cached value is younger than it.
/// 3. When the live call fails after a cached value was emitted, the cached
///    value stands (its age is in the cache's `savedAt`) and nothing more is
///    emitted; without a cached value the failure is emitted.
Stream<Result<T>> watchCachedApiCall<T>({
  required ResponseCache cache,
  required String key,
  required Future<Object> Function() fetch,
  required T Function(Object json) parse,
  Duration? ttl,
}) async* {
  final cached = cache.read(key);
  final fromCache = cached == null ? null : await _parseCached(cached, parse);
  if (fromCache != null) {
    yield fromCache;
    if (ttl != null && _isFresh(cached!, ttl)) return;
  }
  final live = await _fetchLive(cache, key, fetch, parse);
  if (live is Ok<T> || fromCache == null) yield live;
}

bool _isFresh(CachedResponse cached, Duration ttl) =>
    DateTime.now().difference(cached.savedAt) < ttl;

/// Requests in flight per cache key: a second caller asking for the same key
/// while the first request is running shares it instead of sending another.
final Map<String, Future<Object>> _inFlight = {};

Future<Result<T>> _fetchLive<T>(
  ResponseCache cache,
  String key,
  Future<Object> Function() fetch,
  T Function(Object json) parse,
) => runApiCall(() async {
  // Block body on purpose: `remove` returns the removed future — this very
  // one — and returning it from `whenComplete` would make it wait on itself.
  final json = await (_inFlight[key] ??= fetch().whenComplete(() {
    _inFlight.remove(key);
  }));
  final value = parse(json);
  await cache.write(key, json);
  return value;
});

/// A cached body that no longer parses (older app version) is ignored.
Future<Ok<T>?> _parseCached<T>(
  CachedResponse cached,
  T Function(Object json) parse,
) async {
  final result = await runApiCall(() async => parse(cached.data));
  return result is Ok<T> ? result : null;
}
