# MolBhav (Flutter)

Android/iOS app recreating the MolBhav design-system sample screens.

## Run

```sh
flutter pub get
dart run build_runner build   # injectable DI config
flutter run --dart-define=API_BASE_URL=https://<backend>
```

Localizations regenerate automatically (`flutter: generate: true`); ARB files
live in `lib/core/l10n/arb`. English, Hindi and Marathi are translated;
Gujarati, Tamil, Telugu and Kannada fall back to English until translations
are added.

## Structure

```
lib/
  app/            MaterialApp.router, theme + locale wiring
  core/           di, error (Failure/Result), network (Dio, api_call),
                  l10n, locale, router, storage, theme tokens, utils
  shared/widgets/ MolBhav UI kit (Mb* components, 50-icon set)
  features/<feature>/{domain,data,presentation}
```

## Sample screens → features

| Feature | Screens | Status |
| --- | --- | --- |
| auth | Login, Verify OTP | done |
| onboarding | Business profile, Select category | done |
| home | Home + bottom-nav shell | done |
| markets | Market comparison, Price trends, Buying opportunity | done |
| watchlist | Watchlist | done |
| alerts | Alerts, Create alert | done |
| tools | Cost estimator, Reports | done |
| account | More, Subscription | done |

## API contract assumed by the implemented slices

All requests send `Accept-Language` (app language) and, once signed in,
`Authorization: Bearer <accessToken>`. Error bodies may carry `message`
(or RFC 7807 `detail`/`title`), shown to the user as-is.

| Method | Path | Body → Response |
| --- | --- | --- |
| POST | `/auth/otp/request` | `{phoneNumber}` → `{otpLength, resendAfterSeconds}` |
| POST | `/auth/otp/verify` | `{phoneNumber, code}` → `{accessToken, refreshToken, isOnboarded}`; 400/401/422 = wrong or expired code |
| GET | `/reference/business-types` | → `[{id, name}]` |
| GET | `/reference/states` | → `[{code, name}]` |
| GET | `/reference/states/{code}/districts` | → `[{code, name}]` |
| PUT | `/me/business-profile` | `{businessTypeId, stateCode, districtCode, preferredLanguage}` |
| GET | `/categories` | → `[{id, code, name, highlights[], isAvailable}]` |
| PUT | `/me/categories` | `{categoryIds[]}` |

Phone numbers are E.164 (`+919876543210`). Adjust the paths in the
`*_remote_data_source.dart` files once the real endpoints are shared.

## Pending — no approved design

These actions are visible (the designed screens show them) but disabled,
because no screen for them exists in the design system, the BRD, or the
brand board. Supplier discovery is listed in the BRD as a future
enhancement.

| Pending screen | Entry point (disabled) |
| --- | --- |
| Suppliers | Buying Opportunity → "View {market} Suppliers" |
| Edit requirement | Buying Opportunity → edit icon |
| Watchlist search / add item | Watchlist app bar |
| Alert settings | Alerts app bar |
| Help & support | More → Help & support |

## Session

- `SessionManager` (`lib/core/session`) owns the session; the router listens
  to it. A stored refresh token skips Login; unfinished onboarding reopens
  onboarding.
- `AuthInterceptor` renews the access token once on a 401 (concurrent 401s
  share one refresh) and retries. If renewal fails, the session is cleared
  and Login shows "session expired". OTP calls opt out via
  `AuthInterceptor.skipAuth`.
- **Pending:** the refresh-token endpoint contract. `PendingTokenRefresher`
  returns no tokens, so today an expired token ends the session. Bind a real
  `TokenRefresher` when the contract is shared.

## Offline prices

`runCachedApiCall` (`lib/core/cache`) is network-first: successful responses
are stored (per language) and served when the network fails. Used by Home,
commodities, market comparison, price trends and watchlist. Cached data keeps
its original "Updated …" timestamp. The cache is cleared on sign-out/expiry.
