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

includeBuild("../libs/service-registrar")