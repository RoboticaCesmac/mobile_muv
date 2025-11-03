// Importações necessárias para Kotlin DSL
import java.util.Properties
import java.io.File
import java.io.FileInputStream

// 1. Cria um objeto de propriedades (sintaxe Kotlin)
val envProperties = Properties()
// 2. Aponta para o arquivo .env (com aspas duplas)
val envFile = File(rootProject.projectDir, "../../.env")

// 3. Carrega o arquivo .env se ele existir (sintaxe Kotlin)
if (envFile.exists()) {
    envFile.inputStream().use { input ->
        envProperties.load(input)
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.citec.muv"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.citec.muv"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Cria uma variável para o AndroidManifest ler. Pega o valor de 'GOOGLE_MAPS_APAI_KEY' do .env
        manifestPlaceholders.put("GOOGLE_MAPS_API_KEY", envProperties.getProperty("GOOGLE_MAPS_API_KEY", "missing_key"))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
