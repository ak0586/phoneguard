import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.kyvronix.phoneguard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { stream ->
            keystoreProperties.load(stream)
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { path -> rootProject.file(path) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kyvronix.phoneguard"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // R8 full-mode: shrinks + obfuscates all Kotlin/Java code.
            // Renames classes, methods, fields to single letters (a, b, c...).
            // Removes all unused code paths and dead methods.
            isMinifyEnabled = true

            // Strip unused Android resources (drawables, layouts, strings, etc.)
            isShrinkResources = true

            proguardFiles(
                // Android's built-in rules (handles reflection for Android APIs)
                getDefaultProguardFile("proguard-android-optimize.txt"),
                // Our custom rules — keeps Firebase, SMS receivers, etc. intact
                "proguard-rules.pro"
            )
        }
        debug {
            // Keep debug builds unobfuscated for easy development & debugging
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    implementation("androidx.lifecycle:lifecycle-service:2.6.2")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.android.gms:play-services-location:21.1.0")
    implementation("com.google.guava:guava:31.1-android")
}
