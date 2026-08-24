pluginManagement {
    includeBuild("../build-logic")
}

includeBuild("../discovery")
includeBuild("../imprint")
includeBuild("../libs/codegen-utils")
includeBuild("../libs/service-communicator")
includeBuild("../libs/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "realm-capabilities"

include(":realm-capability-types", ":realm-capability-codegen", ":realm-capability-testing")
project(":realm-capability-types").projectDir = file("types")
project(":realm-capability-codegen").projectDir = file("codegen")
project(":realm-capability-testing").projectDir = file("testing")
