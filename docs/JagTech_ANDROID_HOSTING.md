# JagTech Android App Hosting & Deployment

## 1. Purpose

Standard architecture and release process for JagTech Android applications.

**Brand:** JagTech  
**Domain:** `jagtech.in`  
**Production API:** `https://api.jagtech.in`

Flutter is the preferred mobile framework where applicable.

## 2. Android Apps Are Not Normally Hosted on the VPS

The Android application is distributed through Google Play.

```text
Flutter Source
     |
GitHub
     |
Build + Test
     |
Signed Android App Bundle (.aab)
     |
Google Play Console
     |
Android Users
```

The backend is hosted by JagTech:

```text
Android App
     |
     | HTTPS
     v
https://api.jagtech.in
     |
ASP.NET Core API
     |
PostgreSQL
```

## 3. Architecture

```text
                 Internet
                    |
               Cloudflare
                    |
             api.jagtech.in
                    |
                 Nginx
                    |
              ASP.NET Core
                    |
               PostgreSQL
                    ^
                    |
              HTTPS / JSON
                    |
             Flutter Android
```

## 4. API Environments

Development:

```text
http://localhost:xxxx
```

Optional staging:

```text
https://staging-api.jagtech.in
```

Production:

```text
https://api.jagtech.in
```

Do not hardcode development URLs into production builds.

## 5. Flutter Network Architecture

Prefer:

```text
UI
 |
Application / State
 |
Repository
 |
API Client
 |
HTTPS
 |
JagTech API
```

Avoid scattering HTTP calls throughout UI widgets.

Centralize:
- Base URL
- Headers
- Authentication
- Refresh-token handling
- Errors
- Timeouts
- Retry policy

## 6. Authentication

Use secure storage for access/refresh tokens.

Never store sensitive tokens in plain text files or ordinary preferences.

The API remains responsible for authorization. The mobile application is not a trusted security boundary.

## 7. HTTPS

Production must use:

```text
https://api.jagtech.in
```

Do not disable TLS certificate validation to solve production connection problems.

## 8. Android Application ID

Choose a stable application ID before publishing.

Examples:

```text
in.jagtech.app
in.jagtech.molbhav
in.jagtech.retail
```

Changing an already-published application ID creates a different Android application.

## 9. Android Signing

Production builds must be signed.

Never commit:
- Keystore files
- Keystore passwords
- Signing passwords
- Play service credentials

Prefer secure CI/CD secrets for automated release builds.

## 10. Versioning

Example:

```text
versionName: 1.0.0
versionCode: 1
```

Next release:

```text
versionName: 1.0.1
versionCode: 2
```

`versionCode` must increase for each Play Store release.

## 11. Release Build

Typical commands:

```text
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

The AAB is normally generated under:

```text
build/app/outputs/bundle/release/
```

For local testing:

```text
flutter build apk --release
```

## 12. Google Play Release Flow

```text
Developer
    |
GitHub
    |
Flutter Build
    |
Signed .aab
    |
Google Play Console
    |
    +--> Internal testing
    +--> Closed testing
    +--> Production
    |
Android Users
```

Use internal testing before production releases.

## 13. API + Android Have Separate Deployment Pipelines

### API

```text
GitHub
  |
GitHub Actions
  |
Docker
  |
JagTech VPS
  |
api.jagtech.in
```

### Android

```text
GitHub
  |
GitHub Actions
  |
Flutter build
  |
Signed .aab
  |
Google Play
```

They are connected through the API contract but deployed independently.

## 14. Backward Compatibility

Users update at different times:

```text
User A -> App v1
User B -> App v2
User C -> App v3
```

Avoid immediately removing API fields or endpoints required by supported older versions.

Prefer additive API changes where possible.

## 15. API Versioning

Prefer:

```text
https://api.jagtech.in/api/v1/
```

Future breaking contracts may use:

```text
https://api.jagtech.in/api/v2/
```

Do not create a new API version for every small UI change.

## 16. Push Notifications

If needed, use a notification abstraction:

```text
JagTech API
     |
Notification Service
     |
Firebase Cloud Messaging
     |
Android Device
```

Keep notification logic separate from core business logic where practical.

## 17. File Uploads

Recommended flow:

```text
Flutter
   |
HTTPS
   |
JagTech API
   |
File Storage
```

Do not assume local container storage is permanent.

## 18. Mobile Reliability

For poor or intermittent connectivity:

- Use sensible timeouts.
- Cache appropriate read-only data.
- Avoid unnecessary repeated calls.
- Handle retries carefully.
- Prevent duplicate order/payment submissions.
- Use idempotency where business operations require it.

Do not blindly retry financial or order-creation requests.

## 19. CI/CD

Recommended pipeline:

```text
Git Push
   |
GitHub Actions
   |
Flutter SDK
   |
Dependencies
   |
Analyze
   |
Tests
   |
Build
   |
Sign
   |
AAB
   |
Google Play
```

Automated Play publishing can be introduced after the manual release process is stable.

## 20. Release Checklist

- [ ] Correct production API URL
- [ ] Correct application ID
- [ ] Correct version name
- [ ] Increased version code
- [ ] Production signing configuration
- [ ] No debug logging
- [ ] No development URLs
- [ ] No test credentials
- [ ] No secrets in source control
- [ ] Flutter analyze passes
- [ ] Tests pass
- [ ] Release build succeeds
- [ ] Login tested
- [ ] API connectivity tested
- [ ] Important flows tested
- [ ] Internal testing completed

## 21. API Changes Do Not Always Require an Android Release

If an API changes internally without breaking its contract, the existing Android app can continue to work.

A new Android release is needed when:
- the app itself changes, or
- the API change requires a new client contract.

## 22. Android Hosting Clarification

### Backend hosting

```text
Linux VPS
Docker
Nginx
ASP.NET Core
PostgreSQL
```

### Android distribution

```text
Flutter
  |
AAB
  |
Google Play
  |
Users
```

Do not treat the VPS as the primary Android application distribution platform.

## 23. Claude / Copilot Rules

When modifying a JagTech Flutter/Android application:

1. Inspect before changing.
2. Understand the current architecture.
3. Make a focused plan.
4. Avoid unrelated refactoring.
5. Preserve existing UI/theme unless requested.
6. Keep API calls behind the established service/repository layer.
7. Do not hardcode secrets.
8. Do not unnecessarily hardcode environment-specific URLs.
9. Validate Android configuration.
10. Run analyzer/tests.
11. Validate the affected flow.
12. Report changes and validation results.
13. Report remaining risks or assumptions.

## 24. Core Principle

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

> **JagTech Android: Build once. Test properly. Sign securely. Release through Google Play. Keep the API backward compatible.**
