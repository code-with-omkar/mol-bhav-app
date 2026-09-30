# Deep links (shared price cards)

Link shape:

```
https://<host>/p/<productId>?mandi=<mandiId>
```

It opens the market-comparison screen for that product with the named mandi
badged. Opened while logged out, the router sends the user to Login carrying
`?from=<the link>` and returns them to it once signed in.

## The host is configured in three places, and they must match

| Where | What | Example |
|---|---|---|
| Dart | `--dart-define=DEEP_LINK_BASE=https://molbhav.in` | builds the links the app shares, and registers the `/p/:productId` route |
| Android | `-Pdeep_link_host=molbhav.in` (Gradle property → `${deepLinkHost}` in the manifest) | the `autoVerify` intent-filter's host |
| iOS | `applinks:molbhav.in` in `ios/Runner/Runner.entitlements` | Associated Domains |

With `DEEP_LINK_BASE` unset — the default — nothing breaks: shared cards carry
the Play Store link instead, and the app registers no `/p/` route. The Android
placeholder defaults to `invalid.example`, so an unconfigured build verifies
nothing and claims no links.

Example build:

```
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.molbhav.in/api/v1 \
  --dart-define=DEEP_LINK_BASE=https://molbhav.in \
  -Pdeep_link_host=molbhav.in
```

## Serving the association files

Both files in this folder must be served from the site root over HTTPS, with
`Content-Type: application/json`, no redirect and no authentication:

| File here | Must be served at |
|---|---|
| `assetlinks.json` | `https://<host>/.well-known/assetlinks.json` |
| `apple-app-site-association` | `https://<host>/.well-known/apple-app-site-association` |

Note the Apple file has **no** `.json` extension but is still served as JSON.

Nginx:

```nginx
location /.well-known/assetlinks.json {
    default_type application/json;
    alias /var/www/molbhav/well-known/assetlinks.json;
}

location /.well-known/apple-app-site-association {
    default_type application/json;
    alias /var/www/molbhav/well-known/apple-app-site-association;
}
```

Android fetches `assetlinks.json` at install time, so a change only takes
effect on a fresh install (or `adb shell pm verify-app-links --re-verify
com.molbhav.mol_bhav`). Apple caches its file through a CDN; allow time after
a change.

## Before this works

- [ ] `assetlinks.json`: replace both `TODO_..._SHA256` entries. Release key:
      `keytool -list -v -keystore <release.jks> -alias <alias>`. Upload key:
      Play Console → Setup → App signing → *Upload key certificate*. Both are
      needed — Play re-signs the app, so the installed APK carries the release
      key while local `--release` builds carry the upload key.
- [ ] `apple-app-site-association`: replace `TODO_TEAM_ID` with the Apple
      Developer Team ID.
- [ ] iOS only: attach `Runner.entitlements` once in Xcode (Runner → Signing &
      Capabilities → Associated Domains). It is not wired into
      `Runner.xcodeproj` yet, because that edit belongs to Xcode rather than a
      hand-patched `project.pbxproj`.
- [ ] Verify with
      `adb shell am start -a android.intent.action.VIEW -d "https://<host>/p/<productId>?mandi=<mandiId>"`.
