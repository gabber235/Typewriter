pluginManagement {
    includeBuild("../../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "loader"

includeBuild("../../platform/service-registrar")
includeBuild("../../imprint")
includeBuild("../../domain/discovery")

include(":loader-api", ":loader-core", ":loader-standalone", ":loader-paper")
project(":loader-api").projectDir = file("api")
project(":loader-core").projectDir = file("core")
project(":loader-standalone").projectDir = file("standalone")
project(":loader-paper").projectDir = file("paper")
