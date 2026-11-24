# data.gov.in Agmarknet mandi price API (resource 9ef84268-d588-465a-a308-a864a43d0070): reliability, limits, failure modes

Research date: 2026-11-24. Overall finding: I found NO official data.gov.in documentation, status page, announcement, or community-forum thread (searched web; official pages returned 403 or were not indexed) covering limits, quotas, timeouts or outages for this API. Almost everything below is third-party and weakly sourced; items are labelled accordingly. No API keys were used or included.

## Q1. Documented limits (limit max, offset, rate limits/quotas, timeouts, required params)

### Takeaway
No authoritative platform document was retrievable. Third-party guides say: free API key required, `limit` max about 100 on "most datasets" (one guide), no published rate limit (one guide) versus 1,000 requests/day (another), and a shared sample key that returns only about 10 records and is heavily rate-limited. These conflict and are unverified.

### Cited Findings
- Mandi resource id 9ef84268-d588-465a-a308-a864a43d0070 is described as the "Daily mandi price dataset", 2M+ records, updated daily; params `limit` (stated "max 100 on most datasets"), `offset` (0-based, increment by limit until total), filters as `filters[field_name]`; says the key "has no published rate limit"; example uses 30 s client timeout and 0.3 s delay between requests — [themineworks blog](https://themineworks.com/blog/india-government-data-api/) (vendor blog, not official)
- Filter field names are case-sensitive: `filters[State]=Rajasthan` works, lowercase `state` returns no results — [themineworks blog](https://themineworks.com/blog/india-government-data-api/)
- A different guide lists a free tier cap of 1,000 requests per day, key from My Account > API Access — [India Data Atlas](https://indiadataatlas.deccanspatial.com/chapters/ch06-apis/data-gov-api/); conflicts with "no published rate limit" above. Neither is official.
- Shared sample key: one scraper's docs say it returns 10 records per request and is rate limited; its error codes distinguish refused sample key (429), rate-limited personal key (429), refused key (401/403) — [Apify themineworks actor](https://apify.com/themineworks/india-data-gov-scraper.md) (search-snippet level; page not fully read)
- Another Apify actor claims "2000 requests/hour with OAuth 2.0" for an "API v3"; unverified, likely not applicable — [Apify actor](https://apify.com/amaranth_nylon/data-gov-in-actor)
- Request needs `api-key`, `format=json`, and optional `limit`/`offset`; example calls use `format=json&offset=0&limit=1` against this resource id — [GitHub gist](https://gist.github.com/Adarshreddyash/befd988979d1aa09853c7c7ec03033f0)
- Keys are free, generated at data.gov.in My Account — [mandi-lens README](https://github.com/soumyadip-admin/mandi-lens)
- The data.gov.in resource page for this dataset (via search snippet only; page returned 403 to my fetch) reportedly says data is generated through the AGMARKNET portal and, in the snippet, that "API does not exist, submit a request" — [data.gov.in resource page](https://data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi). Treat as unverified; it may be a different/duplicate listing, and the resource id demonstrably works for many developers.
- Do not confuse with the US api.data.gov (separate service with its own documented rate limits, irrelevant here) — [api.data.gov](https://api.data.gov/docs/developer-manual)

### Inferences
- Given a 250-row page works for you, the cap is evidently higher than 100 for this resource, so "max 100" is not universal. Other clients use limit=1000 (see Q3). Exact max is unconfirmed.
- Per-key throttling is plausible but undocumented; your failures (503/500/timeout) are not the 429 pattern third parties describe.

### Gaps
- Official limit maximum, per-key/daily quota, and server-side timeout: not found.
- Official OGD API user manual/FAQ: not retrievable.

## Q2. Reported failure modes (503 HTML, 500, 429, stalls, time-of-day, data lag)

### Takeaway
No developer reports, GitHub issues, Stack Overflow, Reddit or forum threads about data.gov.in mandi API 503/500/timeouts were found. Only indirect evidence exists: developers using very long timeouts, caching and CSV fallbacks, which implies they also see slow/unreliable responses.

### Cited Findings
- A public project calling a data.gov.in mandi endpoint uses `timeout=180` s, no retry, and falls back to a local CSV on network error, non-200, JSON decode error or empty `records`; also caches results to a CSV — [HF Space code](https://huggingface.co/spaces/RushiMane2003/market_trial/discussions/1/files) (note: uses a different resource id 35985678-0d79-46b4-9ed6-6f13308a1d24)
- mandi-lens ingest code guards against last-page over-run vs reported `total`, notes some resources return CSV even with `format=json`, and that one dataset may have multiple resource ids (tries each until one works); schedules ingest 2x/day via Actions or every 6 h in Docker; shows a staleness banner at over 30 h — [mandi-lens README](https://github.com/soumyadip-admin/mandi-lens)
- A third-party wrapper says response schemas vary across resources and have changed over time — [mandi-api blog](https://mandi-api.vercel.app/blog/agmarknet-api-alternative)
- That wrapper re-syncs daily at 8:30 PM IST (its own schedule, not the source's) — [mandi-api blog](https://mandi-api.vercel.app/blog/agmarknet-api-alternative)
- Python `datagovindia` wrapper and an R counterpart include a server-status check function, implying the API server being down is a known enough case — [PyPI datagovindia](https://pypi.org/project/datagovindia/0.4) (search snippet; R function `check_datagovin_server()` from [CRAN pdf](https://ftp.heanet.ie/pub/cran.r-project.org/web/packages/datagovindia/datagovindia.pdf) snippet)
- The exact string "503 Service Unavailable - No server is available to handle this request" is a generic load-balancer (HAProxy/OpenStack-style) page; searches only surfaced it for the unrelated Zerodha Kite API — [Kite forum](https://kite.trade/forum/discussion/comment/47594/). No data.gov.in attribution found.
- Third-party mirrors of Agmarknet data show lagging "last updated" dates (20-04-2025 retrieved 30-04-2025; another July 2025), suggesting the source sometimes isn't refreshed on schedule — [CKAN mirror](https://ckandev.indiadataportal.com/dataset/apmc-arrivals-and-prices) (indirect, weak)
- Other Indian govt APIs (ABDM) have documented 504/timeouts attributed to server load and a fix where requests from outside India were routed badly — [ABDM forum](https://devforum.abdm.gov.in/t/abha-requests-are-being-timed-out/6155); different platform, only an analogy.

### Inferences
- 503 "No server is available" means the gateway has no healthy backend; it is server-side and transient, so retry with long backoff is appropriate; it is not caused by client query shape.
- Your 6-7 minute successes for ~30 rows, plus one 17 s connect then 0.1 s repeats, suggest slow backend/cold path or connection-level queuing rather than row volume; a cold first request being slow and repeats being fast is consistent with server-side caching or connection warm-up (inference, unconfirmed).
- Retries within a short window likely hit the same degraded backend; spreading attempts across hours is likely more effective than more rapid retries.

### Gaps
- No evidence on 429 behavior, time-of-day patterns, or a 2025-2026 status page/maintenance announcement. No NIC/MeitY announcement found.
- No source quantifying that the previous day's rows are often absent until later; only the aggregator's 8:30 PM IST sync hints at evening publication.

## Q3. Faster query shapes; arrival_date filter format

### Takeaway
No source documents faster query shapes. Filtering by State/Commodity/Market/Arrival_Date uses `filters[Field]`; field names are case-sensitive. The arrival_date value in responses is DD/MM/YYYY; the filter format for DD/MM/YYYY is plausible but only weakly evidenced.

### Cited Findings
- Response sample shows `"arrival_date": "11/05/2026"` (DD/MM/YYYY, inferred from sample) — [DEV post](https://dev.to/shariqmirza/i-built-a-real-time-indian-mandi-price-api-heres-how-50k9)
- A project originally sent `filters[Arrival_Date]` in dd/MM/yyyy plus `limit=1000`, later removed both and filter locally by State/District only, no pagination; parses dates with `dayfirst=True` — [HF Space code](https://huggingface.co/spaces/RushiMane2003/market_trial/discussions/1/files) (no reason stated for removal)
- mandi-lens parser accepts input dates in 8 formats, including DD/MM/YYYY — [mandi-lens README](https://github.com/soumyadip-admin/mandi-lens)
- Filter casing varies in the wild: `State`, `District`, `Arrival_Date` (HF code) versus lowercase failing (themineworks); verify against the response field names for your resource (this resource's fields are often lowercase-ish like `state`, `arrival_date` in JSON output; I could not confirm which casing the filters need — test it).
- Other consumers use limit=1000 per request — [HF Space code](https://huggingface.co/spaces/RushiMane2003/market_trial/discussions/1/files)

### Inferences
- One date per request with `filters[arrival_date]=DD/MM/YYYY` (or `Arrival_Date`) is the natural shape; adding `filters[state]` splits the pull into smaller, possibly faster slices. If your date filter returns empty fast but the full call is slow, filter cost may be a factor; cannot confirm.
- Since ~30 rows came back after 6-7 min, row count is not the bottleneck; reducing page size likely will not help much and offset deep-paging is irrelevant at that size.

### Gaps
- No evidence on offset deep-paging penalty, or that filtered queries are faster. Date filter format not officially confirmed.

## Q4. Better times of day, server-side caching, announcements 2025-2026

### Takeaway
Nothing authoritative found. No status page, no maintenance notices, no documented caching or best call windows.

### Cited Findings
- No status page or announcement found in searches for data.gov.in API outages/maintenance 2025-2026 (searches of web returned no relevant results).
- Third-party daily refresh patterns: wrapper syncs at 8:30 PM IST; another project runs ingest twice daily/every 6 h with staleness banner at 30 h — sources above.
- Agmarknet ceda mirror publishes cleaned data with YYYY-MM-DD dates and may be an alternative source — [CEDA Agmarknet README](https://agmarknet.ceda.ashoka.edu.in/README.html) (search snippet; fetch 404)

### Inferences
- Practical mitigations (not from sources, engineering judgment): schedule pulls in off-peak hours and evening IST after the day's data is published; make the job idempotent and resumable; use per-attempt timeouts of 60-180 s with jittered exponential backoff, retries separated by minutes, not seconds; treat HTML bodies as transient 5xx; fall back to cached data and surface a "stale" banner; reuse HTTP connections; consider an alternative source (e.g. the CEDA mirror) when the API is down for hours.
- The "30 s on 5 attempts" failure versus 6-7 min successes suggests the 30 s timeout configuration may differ from the 120 s one; verify which timeout actually applied.

### Gaps
- Official status/maintenance channel, time-of-day behavior, server-side caching: not found. Recommend contacting data.gov.in support or the OGD community forum (community.data.gov.in, not retrievable) for confirmation.
