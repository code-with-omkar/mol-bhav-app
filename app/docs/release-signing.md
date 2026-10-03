# Android release signing

Release builds are signed with the key described in `android/key.properties`. That file and the keystore are
**never committed** (both are gitignored). Without `key.properties` the release build falls back to the debug key,
which is fine for `flutter run --release` and wrong for any store upload.

## One-time setup

```powershell
# Pick a location outside the repo for the keystore and back it up: losing it means losing the ability to update the app.
keytool -genkey -v -keystore $env:USERPROFILE\molbhav-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `app/android/key.properties`:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=C:\\Users\\<you>\\molbhav-upload.jks
```

## Build

```powershell
cd app
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://<api-domain>/api/v1 `
  --dart-define=DEEP_LINK_BASE=https://app.jagtech.in `
  -Pdeep_link_host=app.jagtech.in
```

Then take the SHA-256 of the upload key (`keytool -list -v -keystore <jks> -alias upload`) and put it in
`docs/deep-links/.well-known/assetlinks.json` before hosting that file on `app.jagtech.in`.
If Play App Signing is on, also add the **app signing** certificate fingerprint shown in the Play Console.
