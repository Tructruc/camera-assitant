plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val ciKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val ciKeystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val ciKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")
val ciKeyAlias = System.getenv("ANDROID_KEY_ALIAS")

android {
    namespace = "app.photographyassistant.photography_assistant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.photographyassistant.photography_assistant"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (
            ciKeystorePath != null &&
            ciKeystorePassword != null &&
            ciKeyPassword != null &&
            ciKeyAlias != null
        ) {
            create("ciRelease") {
                storeFile = file(ciKeystorePath)
                storePassword = ciKeystorePassword
                keyAlias = ciKeyAlias
                keyPassword = ciKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("ciRelease")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
