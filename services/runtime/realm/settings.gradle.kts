pluginManagement {
    includeBuild("../../build-logic")
    includeBuild("../../imprint")
    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

includeBuild("../../domain/discovery")
includeBuild("../../domain/elements")
includeBuild("../../domain/library")
includeBuild("../../domain/presentation")
includeBuild("../../domain/pages")
includeBuild("../realm-capabilities")
includeBuild("../../domain/typewriter-types")
includeBuild("../../imprint")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "realm"

includeBuild("../../platform/service-utils")
includeBuild("../../platform/service-telemetry")
includeBuild("../../platform/service-registrar")
includeBuild("../../platform/service-file-transfer")
includeBuild("../loader")
includeBuild("../engine")
