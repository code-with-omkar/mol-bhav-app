# Phase 5 verification — A1–A3, B, C, D, E

Status key: **PASS** verified and working · **FAIL** verified broken ·
**NOT RUN** not yet executed (nobody has driven this on a device).

> Everything below marked NOT RUN needs a person at an Android emulator and a
> Chrome window. It is recorded here as an unfilled checklist rather than a
> guess, so the gap is visible. Screenshot paths are the filenames to save
> into `docs/verification/screenshots/` as each row is run.

## How to run the two targets

```sh
# API (Development: OTP goes to the console, Agmarknet is mocked)
cd source/api/src/MolBhav.Api
ASPNETCORE_ENVIRONMENT=Development dotnet run

# App — Android emulator (10.0.2.2 is the host from inside the emulator)
cd source/app
flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://10.0.2.2:5199/api/v1 \
  --dart-define=DEEP_LINK_BASE=https://molbhav.in \
  -Pdeep_link_host=molbhav.in

# App — Chrome
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5199/api/v1
```

Log in with `9876543210`; the OTP is printed to the API console as
`[DEV OTP] Code for ******3210: NNNNNN`.

---

## Static and service-level checks (done)

| Check | Result | Evidence |
|---|---|---|
| `dotnet build` | **PASS** | 0 errors, 0 warnings |
| `flutter analyze` | **PASS** | No issues found |
| `flutter build web` | **PASS** | Built, incl. `--dart-define=DEEP_LINK_BASE` |
| `flutter build apk --debug` | **FAIL — environment** | see "Android builds are blocked" below |
| EF migrations apply | **PASS** | `dotnet ef database update` → Done (7 migrations added across phase 5) |

### Android builds are blocked on this machine

```
Package 28.2.13676358 not found.
A problem occurred configuring project ':app'.
> Process 'command '…\cmdline-tools\latest\bin\sdkmanager.bat'' finished with
  non-zero exit value -1073740791 (NTSTATUS 0xC0000409)
```

The Flutter Gradle plugin pins `ndkVersion = 28.2.13676358`, no NDK is
installed (`%LOCALAPPDATA%\Android\sdk\ndk` does not exist), and the
auto-install crashes in the new Android CLI wrapper that `sdkmanager.bat` now
forwards to. This fails during *configuration* of `:app`, before any app code
or manifest is read, and reproduces identically on a clean retry — it is not
caused by the phase-5 changes, but it blocks every Android row in this
document.

Fix before running section E on Android:

```sh
# Android Studio → SDK Manager → SDK Tools → NDK (Side by side) → 28.2.13676358
# or, if the CLI is healthy:
sdkmanager --install "ndk;28.2.13676358"
```

Until then the Android manifest change for App Links (the `${deepLinkHost}`
placeholder and the `autoVerify` intent-filter) is **unverified by build** —
it is a syntactic edit reviewed by eye only. Chrome rows can still be run.

---

## E1. Edit profile

| # | Step | Expected | Android | Chrome | Screenshot |
|---|---|---|---|---|---|
| 1 | More → tap the profile row | Name, business type, state, district, language, categories all preselected from the saved profile | NOT RUN | NOT RUN | `e1-prefill.png` |
| 2 | Change the district, save | Returns to More; Home's location line shows the new district without a manual refresh | NOT RUN | NOT RUN | `e1-home-after-save.png` |
| 3 | Change the language, save | UI strings and API-localised names switch at once (`ProfileCubit` listens to `LocaleCubit` and refetches) | NOT RUN | NOT RUN | `e1-language.png` |

Note on step 1: `stateId`/`districtId` preselect only when the saved free-text
state/district matched a market-master row. A profile saved with a name that
matches nothing falls back to the text value and the picker opens unset — that
is the API's documented behaviour (`UserProfileResponse`), not a bug to file.

## E2. Browse by mandi

| # | Step | Expected | Android | Chrome | Screenshot |
|---|---|---|---|---|---|
| 1 | Markets → Browse by mandi | State picker populated; district and mandi disabled until the level above is chosen | NOT RUN | NOT RUN | `e2-pickers.png` |
| 2 | Pick state → district → mandi | Latest price per product at that mandi | NOT RUN | NOT RUN | `e2-prices.png` |
| 3 | Read a row's meta line | Shows the price date and the source name | NOT RUN | NOT RUN | `e2-freshness.png` |
| 4 | Pick a mandi with no recent data | Empty state, not an error or a blank list | NOT RUN | NOT RUN | `e2-empty.png` |

## A1. Create Alert (products/markets load; three conditions; crossing fires)

| # | Step | Expected | Status | Evidence / screenshot |
|---|---|---|---|---|
| 1 | Alert rule with `thresholdType=PriceBelow`, `thresholdPrice=1300` | 201 | **PASS** | API, curl |
| 2 | Same rule sent with `thresholdPercent` instead | 400 (validator + `ck_alert_rules_threshold`) | **PASS** | API, curl |
| 3 | 1100 → 1200 with a PriceBelow-1300 rule | No alert (already below; not a crossing) | **PASS** | API, curl |
| 4 | 1200 → 1500 with a PriceAbove-1300 rule | Alert fires | **PASS** | API, curl |
| 5 | 1500 → 1250 with a PriceBelow-1300 rule | Alert fires | **PASS** | API, curl |
| 6 | Open Create Alert in the app | Product picker lists the user's category products; market picker lists mandis, user's state first | NOT RUN | `a1-pickers.png` |
| 7 | Save each of below / above / % | Three rules created, each with the right `thresholdType` | NOT RUN | `a1-conditions.png` |
| 8 | Choose product + mandi | Helper line shows the current modal price *for that mandi* | NOT RUN | `a1-current-price.png` |
| 9 | Open Create Alert from a comparison row, a trend and a watchlist row | Product and mandi preselected | NOT RUN | `a1-preselect.png` |

## A2. Market comparison — category selection

| # | Step | Expected | Android | Chrome | Screenshot |
|---|---|---|---|---|---|
| 1 | Markets → tap the Construction chip | Only construction materials in the product picker | NOT RUN | NOT RUN | `a2-construction.png` |
| 2 | Tap Agriculture | Only agri products | NOT RUN | NOT RUN | `a2-agriculture.png` |
| 3 | Home → a category tile → Markets | That category's chip is already selected | NOT RUN | NOT RUN | `a2-from-home.png` |
| 4 | Tap "All" | Every category's products | NOT RUN | NOT RUN | `a2-all.png` |

Cache note: the fix changed the cache key to `markets.commodities.v2`, so a
device that ran an older build picks the corrected data up on first launch
without clearing app data.

## A3. Reports — date and time

| # | Step | Expected | Status | Evidence / screenshot |
|---|---|---|---|---|
| 1 | `GET /reports/{id}` on a fresh report | `requestedAtUtc` + `completedAtUtc`, no `lastDownloadedAtUtc` | **PASS** | API, curl |
| 2 | `GET /reports/{id}/download` then re-read | `lastDownloadedAtUtc` now present (18,468-byte PDF served) | **PASS** | API, curl |
| 3 | Reports screen, new report | Row shows "Requested <date>, <time>" and "Generated …" | NOT RUN | `a3-times.png` |
| 4 | Tap to download, watch the row | "Downloaded …" appears without leaving the screen | NOT RUN | `a3-downloaded.png` |
| 5 | Switch language, reopen Reports | Dates and times formatted for that locale | NOT RUN | `a3-locale.png` |

## B. Token refresh

| # | Step | Expected | Status | Evidence |
|---|---|---|---|---|
| 1 | `AccessTokenLifetimeMinutes: 1`, `ClockSkewSeconds: 0` | JWT `exp - iat = 60` | **PASS** | API, decoded token |
| 2 | Call an endpoint after expiry, then refresh, then retry | 401 → 200 → 200 | **PASS** | API, curl |
| 3 | Three parallel refreshes with one token | 200, 409, 409 — one rotation wins, the rest are `RefreshToken.Superseded` (transient, session survives) | **PASS** | API, curl |
| 4 | Delete all `identity.refresh_tokens`, refresh | 401 `RefreshToken.Invalid` → session ends at Login, no loop | **PASS** | API, curl |
| 5 | Config reverted | `exp - iat = 900` again | **PASS** | API, decoded token |
| 6 | In-app: wait 70s, open Watchlist | Succeeds after one silent refresh | NOT RUN | `b-silent-refresh.png` |
| 7 | In-app: fire three screens at once after expiry | Exactly one `token/refresh` in the API log (interceptor single-flight) | NOT RUN | API log excerpt |
| 8 | In-app: revoke tokens, then act | Lands on Login, no error loop | NOT RUN | `b-session-end.png` |

Step 7's single-flight was read in code and is correct
(`_refreshing ??= _refresh().whenComplete(...)`, assigned synchronously before
any await, so a second 401 reuses the in-flight future). Step 3 shows the API
tolerates it even if it regressed. Neither substitutes for watching the log.

## C. Support module

| # | Step | Expected | Status | Evidence / screenshot |
|---|---|---|---|---|
| 1 | `POST /support/tickets` | 201; `Open`, `messageCount: 1` | **PASS** | API, curl |
| 2 | `GET /admin/support/tickets?status=Open` | Row with `userPhoneNumberMasked: ******3210` | **PASS** | API, curl |
| 3 | Admin reply | 204; ticket `Open` → `InProgress`; thread has both turns in order | **PASS** | API, curl |
| 4 | `GET /notifications` after the reply | Push row titled from `support.reply.title` in the user's language (Hindi observed) | **PASS** | API, curl |
| 5 | Resolve, then user replies | Ticket reopens to `Open` | **PASS** | API, curl |
| 6 | Close, then reply / reply / set status | 400 / 400 / 400 — `Closed` is terminal | **PASS** | API, curl |
| 7 | Another user's ticket id | 404 | **PASS** | API, curl |
| 8 | More → Help & Support | FAQ accordion populated in the UI language; three contact tiles | NOT RUN | `c-help.png` |
| 9 | Tap WhatsApp / Call / Email | WhatsApp opens with the prefilled text; dialler opens; mail draft carries app version + masked phone | NOT RUN | `c-contact.png` |
| 10 | Raise a ticket | Lands on the new thread | NOT RUN | `c-raise.png` |
| 11 | Admin replies (`.http` request 79), pull to refresh | Reply appears as an admin bubble; status badge reads In progress | NOT RUN | `c-thread.png` |
| 12 | After the ticket is closed | Reply box replaced by the closed notice | NOT RUN | `c-closed.png` |

Rows 9 and 12 are the ones that can only fail on a device: the contact tiles
depend on Android package visibility (the `<queries>` block added for
`https`/`tel`/`mailto`), and an emulator with no WhatsApp installed will
correctly show "No app on this device can open that."

## D. Share and deep links

| # | Step | Expected | Status | Evidence / screenshot |
|---|---|---|---|---|
| 1 | `flutter build apk --debug -Pdeep_link_host=molbhav.in` | Builds; manifest placeholder resolves | **FAIL — environment** | missing NDK, see above |
| 2 | Comparison row → share icon | Share sheet with a PNG card and the text message | NOT RUN | `d-share-comparison.png` |
| 3 | Pick WhatsApp | Image and text both arrive in the chat | NOT RUN | `d-whatsapp.png` |
| 4 | Browse-by-mandi row → share | Card names the product, variety, mandi, min/max/modal, date, source | NOT RUN | `d-share-mandi.png` |
| 5 | Trends → app-bar share | Card for the newest point in the range | NOT RUN | `d-share-trend.png` |
| 6 | Switch to Hindi or Marathi, share again | Card text renders in Devanagari, not tofu boxes | NOT RUN | `d-share-devanagari.png` |
| 7 | Chrome → share | Text-only share; PNG lands in downloads | NOT RUN | `d-share-web.png` |
| 8 | More → Invite a friend | Store link with `?ref=<12 hex>` | NOT RUN | `d-invite.png` |
| 9 | `adb shell am start -a android.intent.action.VIEW -d "https://molbhav.in/p/<productId>?mandi=<mandiId>"` | Comparison opens on that product, that mandi badged "Shared" | NOT RUN | `d-deeplink.png` |
| 10 | Same link while logged out | Login → after OTP, lands on the product, not Home | NOT RUN | `d-deeplink-login.png` |
| 11 | Chrome at `/p/<productId>?mandi=<mandiId>` | Same screen, handled by go_router | NOT RUN | `d-deeplink-web.png` |

Row 9 cannot verify *App Links* until the domain serves
`/.well-known/assetlinks.json` with the real key fingerprints — see
[`../deep-links/README.md`](../deep-links/README.md). Until then `adb ... am
start` still proves the route and the highlight, because it bypasses
verification; a real tap from WhatsApp will open the browser instead.

---

## Open items this pass did not close

- **Android is unbuildable here** until the NDK is installed, so every Android
  column is blocked, not merely unrun.
- Nothing in E1–E2, and the app-side halves of A1–A3, B, C and D, has been run
  on a device or in Chrome by anyone. That is the whole of section E.
- Continuing to a deep link after login is wired end to end in code
  (`/p/…` → `/login?from=…` → `/login/verify?from=…` → target) but only row
  D10 proves it; the `from` value is deliberately rejected unless it is an
  in-app path, so test a hostile value like `//evil.example` too.
- `assetlinks.json` needs both SHA-256 fingerprints; the Apple file needs the
  Team ID; `Runner.entitlements` needs attaching in Xcode.
- `Support:WhatsAppNumber`/`Phone`/`Email` are Development placeholders, so
  row C9 will open a chat with a number nobody answers.
- Only `app_en.arb` has the phase-5 strings. `hi`/`mr` are behind and
  `gu`/`kn`/`ta`/`te` are empty, so rows E1.3, A3.5 and D6 will show English
  for anything added in phase 5 while still proving the locale plumbing and
  the Devanagari glyph rendering.
