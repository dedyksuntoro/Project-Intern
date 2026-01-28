import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Baca properties dari file local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.example.pabrik_app" // Sesuaikan dengan nama paket Anda
    compileSdk = 35 // Diubah ke 35 untuk mengatasi warning

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.pabrik_app" // Sesuaikan dengan nama paket Anda
        minSdk = 21
        targetSdk = 35 // Sesuaikan dengan compileSdk
        versionCode = (localProperties.getProperty("flutter.versionCode") ?: "1").toInt()
        versionName = localProperties.getProperty("flutter.versionName")
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Tidak perlu ada tambahan di sini untuk kasus kita
}