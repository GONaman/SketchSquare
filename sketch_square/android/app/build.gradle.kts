import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (gitignored) or, in CI,
// from SKETCHSQUARE_* environment variables. See docs/TESTING.md ("Android release build").
val keyProps = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingValue(propName: String, envName: String): String? =
    keyProps.getProperty(propName) ?: System.getenv(envName)

val releaseStoreFile = signingValue("storeFile", "SKETCHSQUARE_KEYSTORE_PATH")

android {
    namespace = "com.sketchsquare.sketch_square"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.sketchsquare.app"
        // Required by a plugin dependency (Sentry/video); Android 6.0+.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile)
                storePassword = signingValue("storePassword", "SKETCHSQUARE_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "SKETCHSQUARE_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "SKETCHSQUARE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (releaseStoreFile != null) {
                    signingConfigs.getByName("release")
                } else {
                    // No release key configured: debug-sign so local release builds
                    // work. Such an APK must never be uploaded to a store.
                    logger.warn("SketchSquare: no release keystore configured, signing with the debug key")
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
