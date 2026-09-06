pluginManagement {
    includeBuild("build-logic")
    includeBuild("imprint")

    repositories {
        gradlePluginPortal()
        mavenCentral()
        google()
    }
}

plugins {
    id("com.typewritermc.settings-conventions")
}

rootProject.name = "services"

includeBuild("imprint")

val allowedNestedBuilds =
    setOf(
        file("build-logic/settings.gradle.kts").canonicalFile,
        file("imprint/settings.gradle.kts").canonicalFile,
    )
val unexpectedNestedBuilds =
    settingsDir
        .walkTopDown()
        .filter { it.name == "settings.gradle.kts" && it.parentFile != settingsDir }
        .map(File::getCanonicalFile)
        .filterNot(allowedNestedBuilds::contains)
        .toList()
check(unexpectedNestedBuilds.isEmpty()) {
    "Normal service projects must belong to the services build. Unexpected roots: ${unexpectedNestedBuilds.joinToString()}."
}

fun includeProject(name: String, directory: String) {
    include(":$name")
    project(":$name").projectDir = file(directory)
}

includeProject("internal-utils", "platform/internal-utils")
includeProject("protocol", "protocol")
includeProject("typewriter-api", "sdk/typewriter-api")
includeProject("typewriter-codegen", "sdk/typewriter-codegen")
includeProject("service-sdk", "sdk/service-sdk")

includeProject("telemetry", "platform/telemetry")
includeProject("messaging", "platform/messaging")
includeProject("file-transfer", "platform/file-transfer")

includeProject("loader-distribution", "runtime/loader/distribution")
includeProject("loader-api", "runtime/loader/api")
includeProject("loader-core", "runtime/loader/core")
includeProject("loader-standalone", "runtime/loader/standalone")
includeProject("loader-paper", "runtime/loader/paper")
includeProject("engine-api", "runtime/engine/api")
includeProject("engine-core", "runtime/engine/core")
includeProject("engine-minecraft", "runtime/engine/capabilities/minecraft")
includeProject("engine-conformance-base", "runtime/engine/capabilities/conformance-base")
includeProject("engine-conformance-composite", "runtime/engine/capabilities/conformance-composite")
includeProject("engine-panel", "runtime/engine/runtimes/panel")
includeProject("engine-paper", "runtime/engine/runtimes/paper")
includeProject("engine-conformance", "runtime/engine/runtimes/conformance")
includeProject("realm", "runtime/realm")
includeProject("conformance-extension", "extensions/conformance")
