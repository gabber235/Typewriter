pluginManagement {
    includeBuild("../../build-logic")
}

includeBuild("../../domain/discovery")
includeBuild("../../imprint")
includeBuild("../../tooling/codegen-utils")
includeBuild("../../platform/service-communicator")
includeBuild("../../domain/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "realm-capabilities"

include(":realm-capability-types", ":realm-capability-codegen", ":realm-capability-testing")
project(":realm-capability-types").projectDir = file("types")
project(":realm-capability-codegen").projectDir = file("codegen")
project(":realm-capability-testing").projectDir = file("testing")
