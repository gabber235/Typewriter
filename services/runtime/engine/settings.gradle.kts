pluginManagement {
    includeBuild("../../build-logic")
    includeBuild("../../imprint")
}

includeBuild("../loader")
includeBuild("../../domain/discovery")
includeBuild("../../domain/elements")
includeBuild("../../domain/library")
includeBuild("../../domain/pages")
includeBuild("../../domain/presentation")
includeBuild("../realm-capabilities")
includeBuild("../../domain/typewriter-types")
includeBuild("../../imprint")

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "engine"

include(
    ":engine-types",
    ":engine-core",
    ":engine-codegen",
    ":engine-minecraft",
    ":engine-conformance-base",
    ":engine-conformance-composite",
    ":engine-panel",
    ":engine-paper",
    ":engine-conformance",
)
project(":engine-types").projectDir = file("types")
project(":engine-core").projectDir = file("core")
project(":engine-codegen").projectDir = file("codegen")
project(":engine-minecraft").projectDir = file("capabilities/minecraft")
project(":engine-conformance-base").projectDir = file("capabilities/conformance-base")
project(":engine-conformance-composite").projectDir = file("capabilities/conformance-composite")
project(":engine-panel").projectDir = file("runtimes/panel")
project(":engine-paper").projectDir = file("runtimes/paper")
project(":engine-conformance").projectDir = file("runtimes/conformance")
