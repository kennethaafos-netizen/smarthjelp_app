import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 Firebase (Sprint 8)
    id("com.google.gms.google-services")
}

// Les Google Maps API-nøkkelen fra android/local.properties (gitignored)
// slik at nøkkelen ikke commites til repo. Fallback til tom streng hvis
// nøkkel ikke er satt — appen vil starte, men Maps får vannmerke
// "For development purposes only" og kart i SDK-dialog vises som svart.
val mapsApiKey: String = run {
    val props = Properties()
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { props.load(it) }
    }
    props.getProperty("MAPS_API_KEY") ?: ""
}

android {
    namespace = "com.example.smarthjelp_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // Sprint 8 fix: flutter_local_notifications krever core library
        // desugaring for å bruke java.time osv på Android API-er under 26.
        // I Kotlin DSL heter property'en `isCoreLibraryDesugaringEnabled`
        // (Groovy-DSL bruker `coreLibraryDesugaringEnabled`).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.smarthjelp_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Plasseholderen ${MAPS_API_KEY} i AndroidManifest.xml byttes ut
        // med faktisk verdi her. Tom streng er trygt fallback.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Sprint 8 fix: desugar_jdk_libs er det Android Gradle Plugin og
    // flutter_local_notifications faktisk leter etter når
    // isCoreLibraryDesugaringEnabled = true. Versjon 2.1.4 er stabil og
    // kompatibel med AGP 8.11.x og Kotlin 2.2.x.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}