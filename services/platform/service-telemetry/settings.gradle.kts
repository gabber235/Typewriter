pluginManagement {
    includeBuild("../../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "service-telemetry"

include(":service-telemetry-core", ":service-telemetry-console", ":service-telemetry-koin", ":service-telemetry-testing")
project(":service-telemetry-core").projectDir = file("core")
project(":service-telemetry-console").projectDir = file("console")
project(":service-telemetry-koin").projectDir = file("koin")
project(":service-telemetry-testing").projectDir = file("testing")

includeBuild("../service-utils")
