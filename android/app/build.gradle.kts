import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Fjelia CE (scripts/build-android-ce.sh: -P fjelia.ce=true): own app ID,
// name and sign-in scheme, so it installs next to Fjelia, signed with the CE
// release key from the git-ignored android/key-ce.properties when present.
val communityEdition = project.findProperty("fjelia.ce") == "true"
val ceSigning = Properties().apply {
    val file = rootProject.file("key-ce.properties")
    if (communityEdition && file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.aeh.fjelia"
    // permission_handler_android and androidx.glance (home_widget) need API 37,
    // above Flutter's default; the SDK ships it as android-37.0.
    compileSdk = 37
    compileSdkMinor = 0
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for scheduled notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aeh.fjelia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // The health plugin (Health Connect) needs Android 8.0.
        // scripts/dev-android.sh --legacy (-P fjelia.legacySdk=true) builds
        // for Android 7 test phones; the manifest lets the health libraries in.
        minSdk = if (project.findProperty("fjelia.legacySdk") == "true") 24 else 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (communityEdition) applicationIdSuffix = ".ce"
        manifestPlaceholders["appLabel"] = if (communityEdition) "Fjelia CE" else "fjelia"
        manifestPlaceholders["authScheme"] = if (communityEdition) "fjeliace" else "fjelia"
    }

    signingConfigs {
        if (!ceSigning.isEmpty) {
            create("ce") {
                storeFile = file(ceSigning.getProperty("storeFile"))
                storePassword = ceSigning.getProperty("storePassword")
                keyAlias = ceSigning.getProperty("keyAlias")
                keyPassword = ceSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.findByName("ce") ?: signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    // Bundled recognition works offline, including the first console photo.
    implementation("com.google.mlkit:text-recognition:16.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
