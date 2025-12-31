plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.strideon"
    compileSdk = 36
    
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.strideon"
        minSdk = 29
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        // Provide required manifest placeholder for AppAuth-based dependencies
        // Using a non-null constant string to avoid Kotlin DSL nullability issues
        manifestPlaceholders["appAuthRedirectScheme"] = "com.strideon"

        // Base URL for the backend API (override per build type if needed)
        buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:8000\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    // Google Maps and Location Services
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("com.google.maps.android:maps-ktx:5.2.0")
    implementation("com.google.maps.android:android-maps-utils:3.14.0")
    
    // Networking
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    implementation("com.github.WepinWallet:wepin-android-sdk-login-v1:v0.0.2")
    implementation("com.github.WepinWallet:wepin-android-sdk-widget-v1:v1.1.2")

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.activity)
    implementation(libs.androidx.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}