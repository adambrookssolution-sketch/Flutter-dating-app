plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.affinitysocialclub.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Matches the Android app registered in the client's Firebase project
        // (`affinity-dating-app-cf807` → package `com.example.app`).
        applicationId = "com.example.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Explicit override of the built-in `debug` signing config (client
    // 2026-05-19 #1). Without this, AGP would auto-generate a fresh
    // keystore inside the project's build/ directory on each clean
    // build — the apksigner audit on build #95 confirmed the APK was
    // signed with cert SHA c4259470… instead of the pinned keystore's
    // 7b109bf6… that we registered in Firebase, so Google Sign-In
    // failed with DEVELOPER_ERROR on the device. Pointing the debug
    // signingConfig at the same ~/.android/debug.keystore the CI
    // workflow places forces AGP to use OUR pinned cert.
    signingConfigs {
        getByName("debug") {
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        // Release signing pulls credentials from CI env (set by the
        // production workflow from GitHub Secrets) or from a local
        // `android/key.properties` file (gitignored). When neither is
        // present we leave the release signingConfig unset and the
        // `release` build type falls back to the debug keystore — fine
        // for local `flutter run --release` smoke tests but Play Store
        // upload will refuse a debug-signed AAB.
        create("release") {
            val keystorePath = System.getenv("RELEASE_KEYSTORE_PATH")
            val keystorePassword = System.getenv("RELEASE_KEYSTORE_PASSWORD")
            val keyAliasEnv = System.getenv("RELEASE_KEY_ALIAS")
            val keyPasswordEnv = System.getenv("RELEASE_KEY_PASSWORD")
            if (!keystorePath.isNullOrBlank() && file(keystorePath).exists()) {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                keyAlias = keyAliasEnv
                keyPassword = keyPasswordEnv
            }
        }
    }

    buildTypes {
        release {
            // If the release signing config has a storeFile (i.e. CI
            // supplied secrets), use it. Otherwise fall back to debug so
            // `flutter run --release` still works locally without
            // requiring every dev to provision a release keystore.
            signingConfig = if (signingConfigs.getByName("release").storeFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
