// movil/android/app/build.gradle.kts
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // El plugin de Firebase
}

// Bloque para leer configuración de Flutter (necesario en Kotlin DSL)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

// Variables de versión de Flutter
val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.movil" 
    compileSdk = flutter.compileSdkVersion // O usa flutter.compileSdkVersion si te funciona, pero un número fijo es más seguro ahora
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        //agregue esto
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.movil" 
        minSdk = 23 // Obligatorio para Firebase
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true 
            // isShrinkResources = true // A veces causa errores si borra recursos necesarios, mejor false por ahora
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Importar la plataforma BOM de Firebase (Maneja las versiones por ti)
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // Librerías de Firebase (Sin número de versión porque el BOM lo controla)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    // Otras librerías necesarias
    implementation("androidx.multidex:multidex:2.0.1")
}