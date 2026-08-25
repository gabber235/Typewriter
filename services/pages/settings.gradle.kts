pluginManagement {
    includeBuild("../build-logic")
}

includeBuild("../discovery")
includeBuild("../elements")
includeBuild("../imprint")
includeBuild("../library")
includeBuild("../libs/codegen-utils")
includeBuild("../libs/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "pages"

include(":page-types", ":page-codegen", ":page-testing")
project(":page-types").projectDir = file("types")
project(":page-codegen").projectDir = file("codegen")
project(":page-testing").projectDir = file("testing")
