pluginManagement {
    includeBuild("../../build-logic")
    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "service-communicator"

includeBuild("../service-utils")
includeBuild("../service-telemetry")