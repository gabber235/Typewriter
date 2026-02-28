pluginManagement {
    includeBuild("../build-logic")
    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "realm"

includeBuild("../libs/service-utils")
includeBuild("../libs/service-telemetry")
includeBuild("../libs/service-registrar")