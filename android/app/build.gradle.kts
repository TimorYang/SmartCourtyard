import java.io.FileInputStream
import java.util.Properties
import java.util.Base64

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

private fun decodeDartDefines(encodedDefines: String?): Map<String, String> {
    if (encodedDefines.isNullOrBlank()) {
        return emptyMap()
    }

    return encodedDefines
        .split(',')
        .filter(String::isNotBlank)
        .map { encodedDefine ->
            val decodedDefine = runCatching {
                String(Base64.getDecoder().decode(encodedDefine), Charsets.UTF_8)
            }.getOrElse {
                error("Unable to decode a Flutter dart-define for the Android build.")
            }
            val separator = decodedDefine.indexOf('=')
            check(separator > 0) {
                "Malformed Flutter dart-define for the Android build."
            }
            decodedDefine.substring(0, separator) to decodedDefine.substring(separator + 1)
        }
        .toMap()
}

private val facebookPlaceholderAppId = "123456789012345"
private val facebookPlaceholderClientToken = "not-configured"

val dartDefines = decodeDartDefines(project.findProperty("dart-defines")?.toString())
val facebookAppIdDefine = dartDefines["FLINX_FACEBOOK_APP_ID"].orEmpty().trim()
val facebookClientTokenDefine = dartDefines["FLINX_FACEBOOK_CLIENT_TOKEN"].orEmpty().trim()
val facebookDisplayNameDefine = dartDefines["FLINX_FACEBOOK_DISPLAY_NAME"].orEmpty().trim()
val hasFacebookConfiguration = facebookAppIdDefine.isNotEmpty() ||
    facebookClientTokenDefine.isNotEmpty() ||
    facebookDisplayNameDefine.isNotEmpty()

if (hasFacebookConfiguration) {
    check(Regex("^[0-9]+$").matches(facebookAppIdDefine) &&
        facebookAppIdDefine != facebookPlaceholderAppId) {
        "Missing or invalid FLINX_FACEBOOK_APP_ID in Flutter dart-defines."
    }
    check(facebookClientTokenDefine.isNotEmpty() &&
        facebookClientTokenDefine != facebookPlaceholderClientToken) {
        "Missing or invalid FLINX_FACEBOOK_CLIENT_TOKEN in Flutter dart-defines."
    }
    check(facebookDisplayNameDefine.isNotEmpty()) {
        "Missing FLINX_FACEBOOK_DISPLAY_NAME in Flutter dart-defines."
    }
}

val facebookAppId = if (hasFacebookConfiguration) {
    facebookAppIdDefine
} else {
    facebookPlaceholderAppId
}
val facebookClientToken = if (hasFacebookConfiguration) {
    facebookClientTokenDefine
} else {
    facebookPlaceholderClientToken
}
val facebookLoginProtocolScheme = "fb$facebookAppId"

val engageLabAppKey = dartDefines["FLINX_ENGAGELAB_APP_KEY"].orEmpty().trim()
val engageLabChannel = dartDefines["FLINX_ENGAGELAB_CHANNEL"].orEmpty().trim()
    .ifEmpty { "developer" }
val engageLabPrivateProcess = ":remote"

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.feizhou.znty"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.feizhou.znty"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // EngageLab's Android SDK supports API 23 and above.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keep native Facebook configuration in sync with Flutter's dart-defines.
        // The fallback values allow an unconfigured build to start safely while
        // FacebookLoginConfiguration keeps the Flutter action unavailable.
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", facebookClientToken)
        resValue("string", "fb_login_protocol_scheme", facebookLoginProtocolScheme)

        manifestPlaceholders["ENGAGELAB_PRIVATES_APPKEY"] = engageLabAppKey
        manifestPlaceholders["ENGAGELAB_PRIVATES_CHANNEL"] = engageLabChannel
        manifestPlaceholders["ENGAGELAB_PRIVATES_PROCESS"] = engageLabPrivateProcess
        manifestPlaceholders["XIAOMI_APPID"] = ""
        manifestPlaceholders["XIAOMI_APPKEY"] = ""
        manifestPlaceholders["MEIZU_APPID"] = ""
        manifestPlaceholders["MEIZU_APPKEY"] = ""
        manifestPlaceholders["OPPO_APPID"] = ""
        manifestPlaceholders["OPPO_APPKEY"] = ""
        manifestPlaceholders["OPPO_APPSECRET"] = ""
        manifestPlaceholders["VIVO_APPID"] = ""
        manifestPlaceholders["VIVO_APPKEY"] = ""
        manifestPlaceholders["HONOR_APPID"] = ""
        manifestPlaceholders["APP_TCP_SSL"] = "true"
        manifestPlaceholders["APP_DEBUG"] = "false"
        manifestPlaceholders["COUNTRY_CODE"] = "CN"

    }

    signingConfigs {
        create("release") {
            check(keystorePropertiesFile.exists()) {
                "Missing Android release signing configuration: android/key.properties"
            }
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
    testImplementation("junit:junit:4.13.2")
}
