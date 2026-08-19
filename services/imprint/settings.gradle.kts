pluginManagement {
    includeBuild("../build-logic")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "imprint"

include(":imprint-model", ":imprint-gradle-plugin", ":imprint-testing")
project(":imprint-model").projectDir = file("model")
project(":imprint-gradle-plugin").projectDir = file("gradle-plugin")
project(":imprint-testing").projectDir = file("testing")
