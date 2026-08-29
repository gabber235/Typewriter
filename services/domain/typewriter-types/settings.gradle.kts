pluginManagement {
    includeBuild("../../build-logic")
}

includeBuild("../../platform/service-communicator")
includeBuild("../../tooling/codegen-utils")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "typewriter-types"

include(":typewriter-types-core", ":typewriter-types-ksp", ":typewriter-types-skir")
project(":typewriter-types-core").projectDir = file("core")
project(":typewriter-types-ksp").projectDir = file("ksp")
project(":typewriter-types-skir").projectDir = file("skir")
