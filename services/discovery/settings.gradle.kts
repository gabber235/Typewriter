pluginManagement {
    includeBuild("../build-logic")
}

includeBuild("../imprint")
includeBuild("../libs/codegen-utils")
includeBuild("../libs/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "discovery"

include(":discovery-model", ":discovery-runtime", ":discovery-codegen", ":discovery-testing")
project(":discovery-model").projectDir = file("model")
project(":discovery-runtime").projectDir = file("runtime")
project(":discovery-codegen").projectDir = file("codegen")
project(":discovery-testing").projectDir = file("testing")
