pluginManagement {
    includeBuild("../../build-logic")
}

includeBuild("../service-communicator")
includeBuild("../codegen-utils")
includeBuild("../../discovery")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "typewriter-types"

include(":typewriter-types-core", ":typewriter-types-ksp", ":typewriter-types-codegen", ":typewriter-types-skir")
project(":typewriter-types-core").projectDir = file("core")
project(":typewriter-types-ksp").projectDir = file("ksp")
project(":typewriter-types-codegen").projectDir = file("codegen")
project(":typewriter-types-skir").projectDir = file("skir")
