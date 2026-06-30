plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.skmobiles.sk_mobiles"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget =
                org.jetbrains.kotlin.gradle.dsl
                    .JvmTarget.JVM_17
        }
    }

    defaultConfig {
        applicationId = "com.skmobiles.sk_mobiles"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(
        platform(
            "com.google.firebase:firebase-bom:33.0.0"
        )
    )
    implementation(
        "com.google.firebase:firebase-analytics")
    implementation(
        "com.google.firebase:firebase-auth")
    implementation(
        "androidx.multidex:multidex:2.0.1")
}
