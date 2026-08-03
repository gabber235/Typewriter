rootProject.name = "engine"

plugins {
    id("com.gradle.develocity") version ("3.19.2")
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

develocity {
    buildScan {
        termsOfUseUrl = "https://gradle.com/help/legal-terms-of-use"
        termsOfUseAgree = "yes"
        publishing.onlyIf { System.getenv("CI") != null }
    }
}
include("engine-paper")
include("engine-core")
include("engine-loader")
