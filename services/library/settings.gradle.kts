pluginManagement {
    includeBuild("../build-logic")
}

includeBuild("../discovery")
includeBuild("../elements")
includeBuild("../libs/typewriter-types")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "library"

include(":library-types")
project(":library-types").projectDir = file("types")
