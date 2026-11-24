# Resilient HttpClient patterns for a slow, flaky government REST API in a scheduled .NET 10 job

## Timeouts: connect vs per-attempt vs total, and the HttpClient.Timeout problem

### Takeaway
Use three separate layers: SocketsHttpHandler.ConnectTimeout (connection only), a per-attempt timeout inside the retry, and a total timeout outside the retry. Set HttpClient.Timeout to InfiniteTimeSpan, because a single client-wide timeout shadows or races the resilience handler's timeouts and spans all retries.

### Cited Findings
- AddStandardResilienceHandler stacks five strategies outermost to inner: rate limiter, total timeout (default 30 s), retry (3 retries, exponential, jitter, 2 s base delay), circuit breaker (10% failure ratio, min throughput 100, sampling 30 s, break 5 s), attempt timeout (default 10 s). — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- Standard handler retries and breaks on HTTP 500+, 408, 429 and on HttpRequestException and TimeoutRejectedException. — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- Polly throws TimeoutRejectedException (not TimeoutException) on a Polly timeout. If you write a custom retry ShouldHandle together with a timeout strategy, you must decide to handle it explicitly. — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- Custom pipeline: `httpClientBuilder.AddResilienceHandler("name", b => { b.AddTimeout(total); b.AddRetry(...); b.AddCircuitBreaker(...); b.AddTimeout(attempt); })`. Order of Add* calls = outermost to innermost. Options classes are HttpRetryStrategyOptions and HttpCircuitBreakerStrategyOptions. — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience) (the ordering is stated in the table; the Add* ordering is my reading of the "outermost to innermost" wording, see Inferences)
- Polly timeout strategy: default 30 s, `TimeoutGenerator` for dynamic values, `OnTimeout` callback fires just before TimeoutRejectedException and is the reliable way to be notified when an outer retry swallows the exception. The callback must honour the cancellation token or the timeout is delayed. — [Polly docs: Timeout](https://www.pollydocs.org/strategies/timeout.html)
- Known interplay problem: HttpClient.Timeout (default 100 s) shorter than the handler's total timeout makes the total timeout effectively ignored (150 s total still produced TaskCanceledException at 100 s). Workaround was `Timeout = Timeout.InfiniteTimeSpan`. A fix "Disable HttpClient's timeout for Standard Resilience and Hedging" was merged Aug-Sep 2024 (PR #5363). — [dotnet/extensions#4770](https://github.com/dotnet/extensions/issues/4770)
- SocketsHttpHandler.ConnectTimeout default is InfiniteTimeSpan; must be > 0 or Infinite; cannot be changed after the handler has started a request. — [MS Learn: ConnectTimeout](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.socketshttphandler.connecttimeout)
- HttpClient resolves DNS only when a connection is created; recommended to set PooledConnectionLifetime (docs example 15 min, recommendation text mentions 2 min as an example) so DNS is re-resolved. — [MS Learn: HttpClient guidelines](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
- SocketsHttpHandler exposes ResponseDrainTimeout, MaxResponseDrainSize, MaxResponseHeadersLength, Expect100ContinueTimeout, PooledConnectionIdleTimeout (default values not captured in my fetch). — [MS Learn: SocketsHttpHandler](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.socketshttphandler)

### Inferences
- Why a single HttpClient.Timeout (120 s) is wrong with retries: it is one cancellation timer for the whole SendAsync, so it cannot tell a dead connect from a slow body, cannot give each attempt a fresh budget, and (per #4770) fights the resilience timeouts. Set `client.Timeout = Timeout.InfiniteTimeSpan` explicitly (do it even though newer package versions reportedly do it for you; harmless).
- Suggested layered values for a flaky gov API returning ~250-row JSON pages (starting point, tune from logs): ConnectTimeout 5-10 s (current 15 s is OK but with 4 retries a dead host costs 15 s x 5); per-attempt timeout 30-45 s (time-to-complete-response, covers headers and body if buffered); total timeout per page 90-120 s; total per run enforced by a CancellationTokenSource (see job design). A healthy page should take seconds; waiting 120 s for an attempt that is going to return 503 or stall is the main source of 6-7 minute runs.
- Aggressive short per-attempt timeouts (15-30 s) plus more attempts beat one long wait when the failure mode is a stalled connection or a load balancer that eventually returns "No server is available"; they lose only if the server is genuinely slow but healthy (then raise it, adaptively: first attempt short, later attempts longer via TimeoutGenerator keyed on attempt number from the resilience context).
- Slow bodies: use `HttpCompletionOption.ResponseHeadersRead` and read the stream so that a header-timeout and a body-read timeout can be distinguished; with the Polly attempt timeout cancelling the token, a body stall is still bounded because the token is passed to ReadAsStreamAsync/ReadFromJsonAsync. With the default ResponseContentRead, GetAsync buffers the whole body inside the attempt anyway, which is fine for 250-row pages and simpler. (Engineering judgment, no source found.)
- Warn: a retry loop outside the resilience pipeline that re-calls an HttpClient that has the standard handler multiplies attempts (4 x 4). Use one layer only; the MS docs also say add only one resilience handler.

### Gaps
- Did not verify the exact current defaults of PooledConnectionIdleTimeout/ResponseDrainTimeout and the exact current default values of the package version as of Nov 2026 (Learn pages list Microsoft.Extensions.Http.Resilience v11.0.0 for net-11 preview moniker; a NuGet search result showed 10.8.0 exists). Pin and check the version actually restored.
- No authoritative source found on whether ConnectTimeout applies per address or per whole multi-address connect.

## Retry strategy, Retry-After, status codes, budgets, circuit breaker

### Takeaway
Use exponential backoff with jitter, honour Retry-After via HttpRetryStrategyOptions.ShouldRetryAfterHeader, retry only transient codes (408, 429, 502, 503, 504, optionally one retry of 500), cap total retry time with the outer timeout, and use a circuit breaker with small MinimumThroughput so a run aborts quickly when the server is clearly down. Default breaker settings (min throughput 100) are useless for a job making a few dozen requests.

### Cited Findings
- Polly RetryStrategyOptions defaults: ShouldHandle any exception except OperationCanceledException, MaxRetryAttempts 3, BackoffType Constant, Delay 2 s, MaxDelay null, UseJitter false. Options: Constant/Linear/Exponential, MaxDelay, DelayGenerator, OnRetry. — [Polly docs: Retry](https://www.pollydocs.org/strategies/retry.html)
- With jitter, exponential backoff uses a decorrelated jitter formula (a delay can be shorter than the previous); other types add about +-25%. MaxDelay does not cap values from DelayGenerator. — [Polly docs: Retry](https://www.pollydocs.org/strategies/retry.html)
- Polly docs advise: do not use retry for scheduling (use a job scheduler like Quartz.NET/Hangfire); cap delays with MaxDelay for long retries; OnRetry does not fire for the first call. — [Polly docs: Retry](https://www.pollydocs.org/strategies/retry.html)
- HttpRetryStrategyOptions (Microsoft.Extensions.Http.Resilience) adds `ShouldRetryAfterHeader` ("use the Retry-After header for the retry delays") and `RetryBudget`. — [MS Learn: HttpRetryStrategyOptions](https://learn.microsoft.com/en-us/dotnet/api/microsoft.extensions.http.resilience.httpretrystrategyoptions)
- `options.Retry.UseBudgetedRetries()` enables a retry budget with default values to reduce extra load on a degraded dependency; in custom pipelines use `AddRetryWithBudget`, since Polly's plain AddRetry cannot apply it and throws ValidationException. Page lists v11.0.0 and monikers net-8 to net-11. — [MS Learn: UseBudgetedRetries](https://learn.microsoft.com/en-us/dotnet/api/microsoft.extensions.http.resilience.httpretrystrategyoptionsextensions.usebudgetedretries)
- Retries apply to all HTTP methods by default; `DisableFor(HttpMethod...)` / `DisableForUnsafeHttpMethods()` exist (irrelevant for GET). — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- Polly circuit breaker defaults: FailureRatio 0.1, MinimumThroughput 100, SamplingDuration 30 s, BreakDuration 5 s; if MinimumThroughput is not reached in the sampling window FailureRatio is ignored so the circuit cannot break. `BreakDurationGenerator` allows dynamic break time. When open, BrokenCircuitException is thrown with a `RetryAfter` property. The breaker does not retry; it rethrows. — [Polly docs: Circuit breaker](https://www.pollydocs.org/strategies/circuit-breaker.html)
- Docs example of a customised breaker: SamplingDuration 10 s, FailureRatio 0.2, MinimumThroughput 3. — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)
- Standard retry/breaker treat all 5xx (>=500) as failures, plus 408 and 429. — [MS Learn: HTTP resilience](https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience)

### Inferences
- Suggested retry config for this API: `MaxRetryAttempts = 3` (not 4), `BackoffType = Exponential`, `UseJitter = true`, `Delay = 2-3 s`, `MaxDelay = 30 s`, `ShouldRetryAfterHeader = true`, ShouldHandle = 408, 429, 502, 503, 504, HttpRequestException, TimeoutRejectedException, plus 500 limited to 1 retry (use `args.AttemptNumber` in ShouldHandle: `Outcome.Result.StatusCode == 500 && args.AttemptNumber < 1`). Rationale: 500 from an application bug on a specific request (bad parameters, server-side exception) is usually deterministic; the observed 500s here may however be backend overload surfaced as 500 by the gov stack, so allow exactly one retry and log it. 503 "No server is available" comes from the load balancer (no healthy backend pool member) and typically persists for tens of seconds to minutes; retrying 4 times within 75 s rarely helps and wastes minutes, so prefer fewer fast retries then defer to a later scheduled re-run.
- Clamp any server Retry-After (a gov server might send huge values) with a DelayGenerator wrapper or by aborting the page and deferring if Retry-After exceeds a threshold (e.g., > 60 s -> stop, mark "deferred").
- Circuit-breaker settings for a job-sized workload: `SamplingDuration = 60-120 s`, `MinimumThroughput = 3-5`, `FailureRatio = 0.5-0.6`, `BreakDuration = 30-60 s`; catch `BrokenCircuitException` in the job, stop the run immediately, record "server unavailable", and leave the remainder for the next scheduled attempt. Alternatively a simple job-level rule: abort after N consecutive failed pages (e.g., 2-3) or after a run time budget (e.g., 3 min), which is easier to reason about than ratio-based breaking. Note the breaker only counts executions that go through it, i.e., the circuit counts each attempt (it sits inside retry), so MinimumThroughput 3-5 will trip within a single page's retries, which is the desired fast-fail.
- Retry budget (UseBudgetedRetries) is aimed at services under load; for a single sequential job it adds little. A simpler budget: cap total retries per run (e.g., 8) using a shared counter in OnRetry/context and abort when exceeded.
- Retrying 500 is wasteful when the same request already failed with 500 twice, when body contains a deterministic error message, or when the breaker is open.
- Hedging (AddStandardHedgingHandler) sends parallel duplicate requests; not recommended against a fragile, rate-limited gov API (would add load); mentioned only to rule it out.

### Gaps
- Exact default values of HttpRetryBudgetOptions were not retrievable from the fetched page.
- No sourced data on how NIC/gov load balancers behave on 503 recovery time; the "tens of seconds to minutes" claim is an assumption, derive from your own logs.

## Job design: resumable pulls, idempotency, small requests, partial success, rescheduling, "not yet published"

### Takeaway
Treat each page (or each state/commodity slice) as an independent, checkpointed unit of work; a failed page should not fail the run, and a run should end with a status of Complete, Partial, NotYetPublished or Failed, with a later scheduler tick resuming only the missing units. Polly docs themselves say to use a scheduler, not retries, for long-horizon repetition.

### Cited Findings
- Polly guidance: "don't use retry for scheduling"; use a job scheduler such as Quartz.NET or Hangfire for recurring tasks. — [Polly docs: Retry](https://www.pollydocs.org/strategies/retry.html)
- Polly circuit breaker exposes BrokenCircuitException.RetryAfter and `StateProvider`/`OnOpened` hooks that a job can use to stop early. — [Polly docs: Circuit breaker](https://www.pollydocs.org/strategies/circuit-breaker.html)

### Inferences
(No external source retrieved for this section; these are engineering recommendations derived from the findings above and standard batch-ingestion practice.)
- Checkpoint table, e.g. `IngestionCheckpoint(Feed, BusinessDate, Partition, NextOffset|LastPage, Status, Attempts, LastError, UpdatedUtc, RowsFetched)`. After each successful page: upsert rows then update checkpoint in the same transaction; at the start of a run load the checkpoint for (feed, date) and continue from NextOffset instead of 0.
- Idempotent upsert on the natural key (market, commodity, variety, grade, arrival date) using `INSERT ... ON CONFLICT DO UPDATE` (Postgres) / `MERGE` or EF `ExecuteUpdate` + insert; this makes overlapping or repeated pulls harmless and lets you re-fetch the last page safely.
- Split work into smaller independent requests when the API supports filters (state, commodity, market, date): small requests finish inside attempt timeouts, fail independently and can be retried in parallel with low concurrency (1-2). If only offset paging is available, reduce page size (250 -> 50-100) when a page repeatedly times out (adaptive page size: halve on timeout, floor 25).
- Partial success: continue with the next unit after a unit exhausts retries (record it as failed, with error), but stop the whole run when the circuit opens or a run-level time budget (e.g., 3-4 min) elapses. Run result enum: `Complete`, `Partial` (some units failed or deferred), `NotPublished` (server healthy, 200 with zero rows for the business date, or 404/empty for today's date; no retry storm, just reschedule), `Unavailable` (breaker open/all failures), `Failed` (unexpected). "Not yet published" must be detected from a successful response (HTTP 200 with total=0 / empty records for today) and kept separate from transport failures in logs and UI.
- Scheduling: a recurring tick (every 30-60 min within a window, e.g., 10:00-20:00 IST, then daily catch-up) implemented with a BackgroundService + `PeriodicTimer`, Quartz.NET or Hangfire; each tick asks "is today's feed complete?" from the checkpoint table and exits immediately if yes. Stop ticking once Complete. Add jitter to the schedule (+-5 min) and avoid exact on-the-hour times when many scrapers hit gov servers (assumption; check observed failure-vs-hour from your own logs and move the first attempt to the healthiest hours).
- Use a distributed/DB lock or `SemaphoreSlim` so a slow run does not overlap with the next tick.
- Keep a short "last good data" fallback: serve yesterday's data with an "as of" stamp rather than blanks when today is not yet published.

### Gaps
- No external references retrieved on resumable-ingestion patterns (searched out of budget); the above is not source-backed.
- No data on the Agmarknet/data.gov.in publish times; determine empirically.

## Network: IPv6/IPv4, DNS caching, HTTP version, keep-alive, TLS

### Takeaway
Cap connect time tightly, consider forcing IPv4 (or a ConnectCallback) if the gov endpoint's IPv6 path hangs, set PooledConnectionLifetime to a few minutes so DNS/LB changes are picked up, and for a pull that only runs briefly, HTTP/1.1 with fresh-ish connections is the lowest-risk choice behind NIC-style load balancers.

### Cited Findings
- HttpClient resolves DNS only at connection creation and ignores DNS TTL; set `PooledConnectionLifetime` so connections are recycled and DNS re-resolved (docs example 15 min; singleton recommendation mentions e.g. 2 min). — [MS Learn: HttpClient guidelines](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
- IHttpClientFactory pools handlers; handler lifetime (HandlerLifetime) governs recycling; avoid IHttpClientFactory if you need cookies, since handlers/CookieContainers are shared and reset on recycle. — [MS Learn: HttpClient guidelines](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
- Resilience for a static client: wrap with `new ResilienceHandler(pipeline){ InnerHandler = socketsHandler }`. — [MS Learn: HttpClient guidelines](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)
- ConnectCallback lets you customise each new TCP connection (DNS control, socket options); it must not do TLS (the handler does it); Microsoft warns to implement and test with "utmost care". The default sample uses a dual-mode Socket with NoDelay = true. — [.NET 5 networking improvements](https://devblogs.microsoft.com/dotnet/net-5-new-networking-improvements/)
- HTTP/2 specifics: EnableMultipleHttp2Connections is off by default; KeepAlivePingDelay default Infinite (off), KeepAlivePingTimeout default 20 s, KeepAlivePingPolicy default Always (alternative WithActiveRequests). These only matter if HTTP/2 is negotiated. — [.NET 5 networking improvements](https://devblogs.microsoft.com/dotnet/net-5-new-networking-improvements/)
- Reported (secondary, third-party) behaviour: on Windows, localhost resolving to both ::1 and 127.0.0.1 can cost about 2 s while .NET tries IPv6 first; dotnet/runtime#65375 was closed as not actionable (OS behaviour); workaround is a ConnectCallback forcing IPv4. — [DEV Community](https://dev.to/alexisfranorge/why-your-net-tests-are-10x-slower-on-windows-and-how-to-fix-it-34cn); similar report: [Meziantou](https://www.meziantou.net/forcing-httpclient-to-use-ipv4-or-ipv6-addresses.htm)
- .NET config switch to disable IPv6 entirely: env var `DOTNET_SYSTEM_NET_DISABLEIPV6=true` or runtimeconfig `System.Net.DisableIPv6` (as stated by search summary of MS networking runtime-config docs). — [MS Learn: networking runtime config](https://learn.microsoft.com/th-th/dotNet/core/runtime-config/networking)

### Inferences
- IPv4 forcing recipe (only if tests show IPv6 stalls): `ConnectCallback = async (ctx, ct) => { var addrs = await Dns.GetHostAddressesAsync(ctx.DnsEndPoint.Host, AddressFamily.InterNetwork, ct); var s = new Socket(SocketType.Stream, ProtocolType.Tcp){ NoDelay = true }; try { await s.ConnectAsync(new IPEndPoint(addrs[0], ctx.DnsEndPoint.Port), ct); return new NetworkStream(s, true);} catch { s.Dispose(); throw; } }`. Test first with `curl -4` vs `curl -6` timing against the host to confirm it is the cause; do not add by default.
- ConnectTimeout 15 s is long for a connect; 5-10 s plus a retry is a better use of time, but note that a ConnectCallback replaces the handler's own connect path, so ConnectTimeout semantics should be re-checked if you use one (assumption).
- PooledConnectionLifetime 2-5 min and PooledConnectionIdleTimeout ~1 min fits a bursty job; stale keep-alive connections silently dropped by a load balancer produce "connection reset"/stalls on the first request after idle; a short idle timeout (shorter than the LB idle timeout, which is unknown for NIC) avoids reusing dead connections. A retry on HttpRequestException covers the rest.
- HTTP version: leave default (HTTP/1.1 unless server offers h2 via ALPN). If stalls look like a stuck multiplexed connection, force `DefaultRequestVersion = HttpVersion.Version11` with `VersionPolicy = RequestVersionOrLower`; if h2 is used, enable KeepAlivePingDelay 30-60 s + KeepAlivePingTimeout 10-20 s with WithActiveRequests so dead connections are detected rather than hanging until the attempt timeout.
- TLS on older gov endpoints: do not disable certificate validation globally; if there are handshake failures, check `SslOptions.EnabledSslProtocols` (default is OS-chosen; avoid pinning to old TLS versions), missing intermediate certificates (install on the host), and cipher support on the host OS. If a certificate problem needs a workaround, scope a `RemoteCertificateValidationCallback` to that one host and thumbprint/chain only. (Engineering judgment; no source retrieved.)
- Tools to prove the cause: `curl -v --connect-timeout 5 -w "%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}"` against the endpoint to split DNS / TCP / TLS / TTFB.

### Gaps
- No confirmed source on whether SocketsHttpHandler runs staggered (RFC 8305) or sequential connects across IPv6/IPv4 addresses in .NET 10; one search showed dotnet/runtime#861 (proposal for Happy Eyeballs API in Socket.ConnectAsync) but status/outcome was not verified. Check the runtime source before relying on either behaviour.
- No source specific to NIC load balancer behaviour (idle timeouts, h2 support) or old-gov TLS problems.

## Observability: what to log and surface

### Takeaway
Log one structured line per attempt (feed, unit/page, attempt number, outcome, status code, elapsed ms, whether the timeout came from attempt/total/connect, Retry-After value) and one summary line per run. Resilience events and built-in HTTP metrics already provide most of this.

### Cited Findings
- Polly emits telemetry events on state transitions: circuit closed (Information), opened (Error), half-opened (Warning); timeout event OnTimeout (Error) is only emitted when the timeout cancels the callback; OnRetry callback gets called before each retry delay. — [Polly docs: Circuit breaker](https://www.pollydocs.org/strategies/circuit-breaker.html), [Polly docs: Timeout](https://www.pollydocs.org/strategies/timeout.html), [Polly docs: Retry](https://www.pollydocs.org/strategies/retry.html)
- TimeoutRejectedException and BrokenCircuitException carry `TelemetrySource` identifying the pipeline and strategy that threw. — [Polly docs: Timeout](https://www.pollydocs.org/strategies/timeout.html), [Polly docs: Circuit breaker](https://www.pollydocs.org/strategies/circuit-breaker.html)
- SocketsHttpHandler has `MeterFactory` and `ActivityHeadersPropagator` for custom metrics and distributed tracing. — [MS Learn: SocketsHttpHandler](https://learn.microsoft.com/en-us/dotnet/api/system.net.http.socketshttphandler)
- Polly OnTimeout is "the reliable way to be notified" when an outer retry handles TimeoutRejectedException. — [Polly docs: Timeout](https://www.pollydocs.org/strategies/timeout.html)

### Inferences
- Log fields per attempt: runId, feed, partition/page+offset, attempt (from `args.AttemptNumber + 1` in OnRetry), status code or exception type, elapsed ms of the attempt (Stopwatch around the call or in OnRetry via `args.Duration`), time-to-headers vs time-to-body (use ResponseHeadersRead and two stopwatch marks), bytes/rows received, delay chosen before next retry, and circuit state. Per run: counts of pages ok/failed/deferred, total retries, total elapsed, outcome enum.
- Distinguish "which timeout fired": attach different OnTimeout log messages to the attempt vs total timeout strategies, and note connect timeouts surface as HttpRequestException/TaskCanceledException wrapping a TimeoutException (not Polly), so log inner exception type.
- Persist the last N run summaries in the DB so the app UI can show "last attempt 10:30 - server unavailable - 3 pages missing - next try 11:00".
- Expose .NET built-in metrics (System.Net.Http meters: http.client.request.duration, http.client.open_connections; connection-wait metrics) via OpenTelemetry if available; not verified against docs in this session.

### Gaps
- Exact current names of .NET 10 System.Net.Http metrics were not verified in this research.
- Did not find a reputable engineering article on resilient batch ingestion in the search budget; job-design guidance is therefore mostly inference.

## Suggested composite configuration (summary of inferences; values are starting points, not sourced defaults)

```csharp
services.AddHttpClient<AgmarknetClient>(c => {
        c.BaseAddress = new Uri(baseUrl);
        c.Timeout = Timeout.InfiniteTimeSpan;            // per MS issue dotnet/extensions#4770
    })
    .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler {
        ConnectTimeout = TimeSpan.FromSeconds(8),
        PooledConnectionLifetime = TimeSpan.FromMinutes(5),
        PooledConnectionIdleTimeout = TimeSpan.FromSeconds(60),
        AutomaticDecompression = DecompressionMethods.All,
    })
    .AddResilienceHandler("agmarknet", b => {
        b.AddTimeout(TimeSpan.FromSeconds(100));           // total per page, outermost
        b.AddRetry(new HttpRetryStrategyOptions {
            MaxRetryAttempts = 3,
            BackoffType = DelayBackoffType.Exponential,
            UseJitter = true,
            Delay = TimeSpan.FromSeconds(3),
            MaxDelay = TimeSpan.FromSeconds(30),
            ShouldRetryAfterHeader = true,
            // ShouldHandle: 408/429/502/503/504, HttpRequestException, TimeoutRejectedException; 500 only AttemptNumber < 1
        });
        b.AddCircuitBreaker(new HttpCircuitBreakerStrategyOptions {
            SamplingDuration = TimeSpan.FromSeconds(90),
            MinimumThroughput = 4,
            FailureRatio = 0.6,
            BreakDuration = TimeSpan.FromSeconds(45),
        });
        b.AddTimeout(TimeSpan.FromSeconds(30));            // per attempt, innermost
    });
```
Property names above (ConnectTimeout, PooledConnectionLifetime, PooledConnectionIdleTimeout, ShouldRetryAfterHeader, MaxDelay, UseJitter, SamplingDuration, MinimumThroughput, FailureRatio, BreakDuration) are confirmed in the cited docs; the numeric values are recommendations. Remove the current hand-written retry loop so retries are not multiplied. Pin the Microsoft.Extensions.Http.Resilience version and verify whether the ordering of Add* calls (outermost first) matches your installed version's behaviour in a unit test using a fake handler returning 503s.
