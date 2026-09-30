# JXNext Flutter Android Build & Release

## Purpose

This document defines how JXNext Flutter mobile applications are configured, built, signed, tested, released, and distributed to Android users.

Important:

**The Android application is NOT hosted on the JXNext VPS.**

The VPS hosts the API and PostgreSQL.

The Android application is distributed through Google Play or, when explicitly required, as an APK.

Architecture:

```text
Android Phone
     |
Flutter App
     |
HTTPS
     |
https://api.jxnext.in
     |
JXNext API
     |
PostgreSQL
```

---

## 1. Android Distribution

Primary production distribution:

```text
Flutter source
   |
Release build
   |
Android App Bundle (.aab)
   |
Google Play Console
   |
Google Play
   |
User's Android device
```

The normal production artifact should be:

```text
.aab
```

Use APK for testing, direct internal distribution, or other explicitly required scenarios.

---

## 2. API Configuration

Development API:

```text
http://localhost:xxxx
```

Production API:

```text
https://api.jxnext.in
```

Do not hardcode API URLs throughout the Flutter codebase.

Use a centralized environment/configuration mechanism.

Example:

```text
Development
Staging
Production
```

Production must use HTTPS.

---

## 3. Flutter Architecture

Keep API configuration centralized.

Example concept:

```text
lib/
|
+-- core/
|   +-- config/
|   +-- network/
|   +-- storage/
|
+-- features/
|
+-- shared/
```

The HTTP/API client should use the configured environment base URL.

Do not duplicate API base URLs across services/screens.

---

## 4. Authentication

For authenticated applications:

- use secure token storage
- never store tokens in plain text files
- centralize authentication
- handle token refresh where required
- handle session expiration
- clear credentials on logout
- never embed server/database credentials

Never put:

```text
PostgreSQL password
API secret
JWT signing key
server credentials
```

inside the Flutter application.

Anything shipped inside an Android app should be treated as potentially discoverable by the user.

---

## 5. API Communication

Use HTTPS:

```text
https://api.jxnext.in
```

All API requests should go through a centralized network client/interceptor layer.

The application should handle:

- timeout
- network unavailable
- server errors
- unauthorized responses
- validation errors
- retry where appropriate
- token refresh where appropriate

Do not blindly retry non-idempotent operations such as order/payment creation.

---

## 6. Environment Management

Recommended:

```text
Development
Staging
Production
```

Example:

```text
Development:
http://localhost:7040

Staging:
https://staging-api.jxnext.in

Production:
https://api.jxnext.in
```

Do not use production APIs accidentally during development.

Use clear build flavors/configurations when multiple environments are required.

---

## 7. Android Application Identity

Each production application must have a unique Android application ID.

Example:

```text
com.jxnext.retail
```

Use a stable application ID once the app is published.

Changing the application ID after release creates a different Android application.

---

## 8. Application Signing

Production Android releases must be signed.

Keep signing credentials secure.

Never commit:

- keystore files
- keystore passwords
- key passwords
- Play Console credentials

to Git.

For CI/CD, store sensitive signing information using GitHub Actions secrets or an appropriate secure secret system.

Keep secure backups of the production signing credentials.

Losing the production signing credentials can create serious release/upgrade problems.

---

## 9. Release Build

Typical production command:

```text
flutter build appbundle --release
```

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

For APK testing:

```text
flutter build apk --release
```

Do not distribute debug builds as production releases.

---

## 10. Build Validation

Before creating a production release:

```text
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Where applicable, also validate:

- Android manifest
- permissions
- deep links
- notification configuration
- API production URL
- app icon
- splash screen
- version
- signing
- release configuration

---

## 11. Versioning

Android releases require controlled versioning.

Keep version information in the Flutter project.

Example:

```text
version: 1.0.0+1
```

Conceptually:

```text
1.0.0 = user-facing version
+1    = build number
```

Increment appropriately for each release.

Do not reuse a build number when Google Play requires a new one.

---

## 12. Google Play Release Flow

Typical process:

```text
Developer
   |
GitHub
   |
CI/CD
   |
Flutter build
   |
Signed .aab
   |
Google Play Console
   |
Testing track
   |
Production release
   |
Users
```

Recommended release progression:

```text
Internal testing
      ↓
Closed testing
      ↓
Production
```

Use staged rollout when appropriate.

---

## 13. API and Android Release Coordination

The API and Android app have separate deployment processes.

### API

```text
GitHub
   ↓
GitHub Actions
   ↓
Docker
   ↓
JXNext VPS
   ↓
api.jxnext.in
```

### Android

```text
GitHub
   ↓
GitHub Actions
   ↓
Flutter build
   ↓
Signed AAB
   ↓
Google Play
```

They are connected through the API contract.

---

## 14. Backward Compatibility

This is critical.

Android users do NOT update simultaneously.

For example:

```text
Old App 1.0
Old App 1.1
New App 2.0
```

may all call your API at the same time.

Therefore:

- avoid breaking existing API contracts
- prefer additive API changes
- version APIs when breaking changes are unavoidable
- keep old endpoints temporarily when necessary
- migrate clients gradually

Never deploy a breaking API change assuming every Android user has updated.

---

## 15. Example Feature Release

Suppose you introduce order tracking.

The change may require:

```text
Flutter
+
ASP.NET Core API
+
PostgreSQL
```

Recommended sequence:

```text
1. Add database changes
2. Add backward-compatible API
3. Deploy API
4. Verify API
5. Release new Flutter version
6. Publish to testing
7. Publish to production
```

This prevents the new Android app from depending on an API that does not yet exist.

---

## 16. Push Notifications

If the application requires push notifications, use an appropriate push-notification provider and keep its server credentials on the backend.

Do not put server-side notification credentials in Flutter.

Typical flow:

```text
Flutter
   |
Device token
   |
JXNext API
   |
Push notification provider
   |
Android device
```

---

## 17. File Uploads

For image/document uploads:

```text
Flutter
   |
HTTPS
   |
API
   |
File storage
```

Do not assume the Android application or API container is permanent file storage.

Use a backend abstraction for storage.

---

## 18. CI/CD

Recommended Flutter pipeline:

```text
GitHub
   |
GitHub Actions
   |
Flutter setup
   |
flutter pub get
   |
flutter analyze
   |
flutter test
   |
Build signed AAB
   |
Store artifact
   |
Google Play deployment
```

Google Play publishing can be automated after the release process is properly configured.

Start with manual Play Console upload if that is simpler, then automate once stable.

---

## 19. Release Safety

Before production release verify:

```text
Correct API URL
Correct application ID
Correct version/build number
Release signing
No debug configuration
No development credentials
No test endpoints
No sensitive logs
Production API compatibility
```

Test important flows:

```text
Login
Authentication
Home
Products
Cart
Orders
Payments if applicable
Notifications if applicable
Logout
```

---

## 20. What "Android Hosting" Means

Do not treat Android like a web application.

You do NOT deploy:

```text
Flutter APK/AAB
```

to the JXNext VPS for normal production distribution.

Instead:

```text
Google Play
    |
    v
Android phone
    |
    v
https://api.jxnext.in
    |
    v
JXNext API
```

The VPS hosts the backend.

Google Play distributes the mobile application.

---

## 21. Claude/Copilot Rules

Before changing Flutter release/deployment configuration:

1. Inspect the existing Flutter project.
2. Inspect environment/API configuration.
3. Inspect Android application ID.
4. Inspect signing configuration.
5. Inspect current build/release process.
6. Create a short plan.
7. Avoid unrelated changes.

During implementation:

- preserve existing architecture
- keep API URLs centralized
- do not hardcode secrets
- do not change application ID without explicit approval
- do not commit signing credentials
- keep production HTTPS
- avoid unnecessary packages

After implementation:

Validate:

```text
flutter analyze
flutter test
release build
API configuration
Android manifest
version/build number
signing configuration
```

Report:

```text
Changed
Validated
Potential Risks
Release Notes
```

---

## 22. Core Android Principle

```text
BUILD
  ↓
TEST
  ↓
SIGN
  ↓
CREATE AAB
  ↓
GOOGLE PLAY
  ↓
USERS
```

The Android app is distributed by Google Play.

The JXNext VPS hosts the API and PostgreSQL.

**JXNext mobile principle:**

> Build the app once, release safely, and let the app connect securely to the JXNext API.
