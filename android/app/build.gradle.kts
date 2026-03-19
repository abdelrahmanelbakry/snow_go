plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Google services plugin here (don’t apply yet)
    id("com.google.gms.google-services") version "4.3.15" apply false
}

android {
    namespace = "com.masstech.snow_go"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.masstech.snow_go"
        minSdk = 21  // Required for Firebase Analytics and Crashlytics
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // Add Google Maps API key placeholder
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = "YOUR_PRODUCTION_GOOGLE_MAPS_API_KEY"
    }

    signingConfigs {
        create("release") {
            // Production signing configuration
            keyAlias = "snowgo-release"
            keyPassword = System.getenv("KEYSTORE_PASSWORD")
            storeFile = file("../keystore/snowgo-release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
        }
    }
    
    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
        }
        
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
            
            // Production configuration
            manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = System.getenv("GOOGLE_MAPS_API_KEY_PROD") ?: "YOUR_PRODUCTION_GOOGLE_MAPS_API_KEY"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.3")
    
    // Firebase BOM for version management
    implementation(platform("com.google.firebase:firebase-bom:32.3.1"))
    
    // Firebase Analytics and Crashlytics
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")
    
    // Google Play Services for Maps
    implementation("com.google.android.gms:play-services-maps:18.1.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
}

apply(plugin = "com.google.gms.google-services")
