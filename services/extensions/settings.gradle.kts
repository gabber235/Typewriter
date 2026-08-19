pluginManagement {
    includeBuild("../build-logic")
    includeBuild("../imprint")
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "extensions"

include(":extension-types", ":extension-codegen", ":conformance-extension")
project(":extension-types").projectDir = file("types")
project(":extension-codegen").projectDir = file("codegen")
project(":conformance-extension").projectDir = file("conformance")
