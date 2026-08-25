pluginManagement {
    includeBuild("../build-logic")
    includeBuild("../imprint")
}

includeBuild("../libs/codegen-utils")
includeBuild("../libs/typewriter-types")
includeBuild("../discovery")
includeBuild("../elements")
includeBuild("../library")
includeBuild("../presentation")
includeBuild("../pages")
includeBuild("../realm-capabilities")
includeBuild("../engine")
includeBuild("../imprint")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "extensions"

include(":extension-types", ":conformance-extension")
project(":extension-types").projectDir = file("types")
project(":conformance-extension").projectDir = file("conformance")
