
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")

    // Flutter Gradle Plugin must be applied after Android plugin
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()

val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {
    namespace = "com.oozee.diamx"

    compileSdk = 37

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.oozee.diamx"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 5
        versionName = "1.0.1"
    }

    // Correct release signing configuration
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String

            keyPassword = keystoreProperties["keyPassword"] as String

            storeFile = file(
                keystoreProperties["storeFile"] as String
            )

            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
