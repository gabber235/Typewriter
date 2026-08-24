pluginManagement {
    includeBuild("../build-logic")
    includeBuild("../imprint")
    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

includeBuild("../discovery")
includeBuild("../elements")
includeBuild("../libs/typewriter-types")
includeBuild("../imprint")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "realm"

includeBuild("../libs/service-utils")
includeBuild("../libs/service-telemetry")
includeBuild("../libs/service-registrar")
includeBuild("../libs/service-file-transfer")
includeBuild("../loader")
includeBuild("../engine")
