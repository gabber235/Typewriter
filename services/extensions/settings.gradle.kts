pluginManagement {
    includeBuild("../build-logic")
    includeBuild("../imprint")
}

includeBuild("../tooling/codegen-utils")
includeBuild("../domain/typewriter-types")
includeBuild("../domain/discovery")
includeBuild("../domain/elements")
includeBuild("../domain/library")
includeBuild("../domain/presentation")
includeBuild("../domain/pages")
includeBuild("../runtime/realm-capabilities")
includeBuild("../runtime/engine")
includeBuild("../imprint")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "extensions"

include(":conformance-extension")
project(":conformance-extension").projectDir = file("conformance")
