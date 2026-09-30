# Deep links — `app.jagtech.in`

Decision **D1** (30 Sep 2026): shared links use `https://app.jagtech.in`.

| Layer | Setting | Value |
|---|---|---|
| Dart | `--dart-define=DEEP_LINK_BASE` | `https://app.jagtech.in` |
| Android | Gradle property `-Pdeep_link_host` | `app.jagtech.in` |
| iOS | `ios/Runner/Runner.entitlements` | `applinks:app.jagtech.in` |

All three must match. With `DEEP_LINK_BASE` unset the app registers no deep-link
route and share cards fall back to the Play Store link — safe default.

## Routes

| Path | Target |
|---|---|
| `/p/{productId}?mandi={mandiId}` | `AppRoutes.marketsFor(commodityId, mandiId)` |

## Build commands

```powershell
flutter run --dart-define=DEEP_LINK_BASE=https://app.jagtech.in
flutter build apk --release --dart-define=DEEP_LINK_BASE=https://app.jagtech.in -Pdeep_link_host=app.jagtech.in
flutter build ipa --dart-define=DEEP_LINK_BASE=https://app.jagtech.in
```

## Hosting (`app.jagtech.in`)

Serve both files from `.well-known/` in this folder over HTTPS, no redirects:

| URL | Content-Type |
|---|---|
| `https://app.jagtech.in/.well-known/assetlinks.json` | `application/json` |
| `https://app.jagtech.in/.well-known/apple-app-site-association` | `application/json` (no extension) |

### Fill the placeholders

- **Android SHA-256** — release keystore:
  `keytool -list -v -keystore <release.jks> -alias <alias>` → `SHA256:` line.
  If Play App Signing is on, also add the fingerprint from Play Console → Setup → App signing.
- **iOS Team ID** — Apple Developer → Membership (10 chars). Bundle id: `com.molbhav.molBhav`.

## Manual steps still open

- [ ] Xcode: Runner → Signing & Capabilities → + Associated Domains → attach `Runner.entitlements`
- [ ] Fill SHA-256 + Team ID, deploy `.well-known` files to `app.jagtech.in`
- [ ] Verify Android: `adb shell pm get-app-links com.molbhav.mol_bhav` → `verified`
- [ ] Verify iOS: tap link in Notes on a real device → opens app
