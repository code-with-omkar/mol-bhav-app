import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (gitignored; see docs/release-signing.md).
// Without it the release build falls back to the debug key so `flutter run --release` still works,
// but that APK must never be uploaded to a store.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.molbhav.mol_bhav"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.molbhav.mol_bhav"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Host for the App Links intent-filter. A manifest cannot read a Dart
        // define, so the host is a build property: pass it alongside
        // --dart-define=DEEP_LINK_BASE (e.g. -Pdeep_link_host=app.jagtech.in).
        // The placeholder default is a host nobody owns, so an unconfigured
        // build verifies nothing and claims no links.
        manifestPlaceholders["deepLinkHost"] =
            (project.findProperty("deep_link_host") as String?) ?: "invalid.example"

        // AdMob app id. Defaults to Google's sample id, which only ever serves
        // test ads; release builds pass the real one: -Padmob_app_id=ca-app-pub-…~…
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("admob_app_id") as String?)
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
