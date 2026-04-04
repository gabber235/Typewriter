rootProject.name = "module-plugin"

plugins {
    id("com.gradle.develocity") version ("3.19.2")
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

develocity {
    buildScan {
        termsOfUseUrl = "https://gradle.com/help/legal-terms-of-use"
        termsOfUseAgree = "yes"
    }
}
includeBuild("../engine")
include("api")
include("processor")
include("engine-processor")
include("extension-processor")
