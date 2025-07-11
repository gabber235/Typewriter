dependencyResolutionManagement {
    versionCatalogs {
        create("libs") {
            from(files(rootDir.resolve("./dependencies.toml")))
        }
    }
}

rootProject.name = "engine"

plugins {
    id("com.gradle.enterprise") version ("3.13.3")
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

gradleEnterprise {
    buildScan {
        termsOfServiceUrl = "https://gradle.com/terms-of-service"
        termsOfServiceAgree = "yes"
    }
}
include("engine-paper")
include("engine-core")
include("engine-loader")