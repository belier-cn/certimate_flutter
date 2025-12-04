import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
val keystorePropertiesFile = file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val _storeFile = file(System.getenv("KEYSTORE_FILE") ?: keystoreProperties["storeFile"]?.toString() ?: "certimate.jks")
val _storePassword = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties["storePassword"]?.toString()
val _keyAlias = System.getenv("KEYSTORE_KEY_ALIAS") ?: keystoreProperties["keyAlias"]?.toString()
val _keyPassword = System.getenv("KEYSTORE_KEY_PASSWORD") ?: keystoreProperties["keyPassword"]?.toString()


android {
    namespace = "cn.belier.certimate"
    // https://github.com/flutter/flutter/blob/flutter-3.38-candidate.0/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    defaultConfig {
        applicationId = "cn.belier.certimate"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = _storeFile
            storePassword = _storePassword
            keyAlias = _keyAlias
            keyPassword = _keyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
