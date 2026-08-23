pluginManagement {
    includeBuild("../build-logic")
}

includeBuild("../discovery")
includeBuild("../imprint")
includeBuild("../libs/codegen-utils")
includeBuild("../libs/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "elements"

include(":element-types", ":element-codegen", ":element-testing")
project(":element-types").projectDir = file("types")
project(":element-codegen").projectDir = file("codegen")
project(":element-testing").projectDir = file("testing")
