import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de publication : android/key.properties en local (ignoré par Git), ou
// variables d'environnement MEMO_KEYSTORE_* en CI. Sans elles, la build
// release est signée avec la clé de débogage (PR de Dependabot, forks).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    keyProperties.getProperty(property) ?: System.getenv(env)?.takeIf { it.isNotEmpty() }

val releaseStoreFile = signingValue("storeFile", "MEMO_KEYSTORE_PATH")

android {
    namespace = "com.creyativ.memo"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.creyativ.memo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // prod : l'application publiée. dev : tout le contenu embarqué, installable
    // à côté de prod (identifiant et nom distincts).
    flavorDimensions += "env"
    productFlavors {
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Memo")
        }
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Memo dev")
        }
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile)
                storePassword = signingValue("storePassword", "MEMO_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "MEMO_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "MEMO_KEY_PASSWORD")
            }
        }
    }

    // Même signature pour `flutter run` et l'APK de la CI : l'un peut
    // remplacer l'autre sur un appareil sans désinstaller.
    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
        getByName("debug") {
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }
}

flutter {
    source = "../.."
}
