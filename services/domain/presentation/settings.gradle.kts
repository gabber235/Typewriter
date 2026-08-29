pluginManagement {
    includeBuild("../../build-logic")
}

includeBuild("../discovery")
includeBuild("../../imprint")
includeBuild("../../tooling/codegen-utils")
includeBuild("../../platform/service-communicator")
includeBuild("../typewriter-types")
includeBuild("../../runtime/realm-capabilities")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "presentation"

include(":presentation-types", ":presentation-codegen", ":presentation-testing")
project(":presentation-types").projectDir = file("types")
project(":presentation-codegen").projectDir = file("codegen")
project(":presentation-testing").projectDir = file("testing")
