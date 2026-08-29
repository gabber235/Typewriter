rootProject.name = "services"

data class ServiceBuild(
    val path: String,
    val checkedProjects: List<String>,
) {
    val name: String = path.substringAfterLast("/")
}

val serviceBuilds =
    listOf(
        ServiceBuild("tooling/codegen-utils", listOf(":")),
        ServiceBuild("platform/service-utils", listOf(":")),
        ServiceBuild(
            "domain/typewriter-types",
            listOf(
                ":typewriter-types-core",
                ":typewriter-types-ksp",
                ":typewriter-types-skir",
            ),
        ),
        ServiceBuild(
            "domain/discovery",
            listOf(":discovery-model", ":discovery-runtime", ":discovery-codegen", ":discovery-testing"),
        ),
        ServiceBuild(
            "domain/elements",
            listOf(":element-types", ":element-codegen", ":element-testing"),
        ),
        ServiceBuild("domain/library", listOf(":library-types")),
        ServiceBuild(
            "domain/presentation",
            listOf(":presentation-types", ":presentation-codegen", ":presentation-testing"),
        ),
        ServiceBuild(
            "domain/pages",
            listOf(":page-types", ":page-codegen", ":page-testing"),
        ),
        ServiceBuild(
            "runtime/realm-capabilities",
            listOf(":realm-capability-types", ":realm-capability-codegen", ":realm-capability-testing"),
        ),
        ServiceBuild(
            "platform/service-telemetry",
            listOf(
                ":service-telemetry-core",
                ":service-telemetry-console",
                ":service-telemetry-koin",
                ":service-telemetry-testing",
            ),
        ),
        ServiceBuild(
            "platform/service-http",
            listOf(":service-http-core", ":service-http-jdk", ":service-http-testing"),
        ),
        ServiceBuild(
            "platform/service-communicator",
            listOf(
                ":service-communicator-core",
                ":service-communicator-nats",
                ":service-communicator-skir",
                ":service-communicator-koin",
                ":service-communicator-testing",
            ),
        ),
        ServiceBuild(
            "platform/service-registrar",
            listOf(
                ":service-registrar-core",
                ":service-registrar-runtime",
                ":service-registrar-storage-file",
                ":service-registrar-console",
                ":service-registrar-koin",
                ":service-registrar-testing",
            ),
        ),
        ServiceBuild(
            "platform/service-file-transfer",
            listOf(
                ":service-file-transfer-core",
                ":service-file-transfer-messaging",
                ":service-file-transfer-storage-file",
                ":service-file-transfer-koin",
                ":service-file-transfer-testing",
            ),
        ),
        ServiceBuild(
            "sdk/service-integration-sdk",
            listOf(
                ":service-integration-sdk-types",
                ":service-integration-sdk-client",
                ":service-integration-sdk-messaging",
                ":service-integration-sdk-testing",
            ),
        ),
        ServiceBuild("runtime/realm", listOf(":")),
        ServiceBuild(
            "imprint",
            listOf(":imprint-model", ":imprint-gradle-plugin", ":imprint-testing"),
        ),
        ServiceBuild(
            "runtime/loader",
            listOf(":loader-api", ":loader-core", ":loader-standalone", ":loader-paper"),
        ),
        ServiceBuild(
            "runtime/engine",
            listOf(
                ":engine-types",
                ":engine-core",
                ":engine-codegen",
                ":engine-minecraft",
                ":engine-conformance-base",
                ":engine-conformance-composite",
                ":engine-panel",
                ":engine-paper",
                ":engine-conformance",
            ),
        ),
        ServiceBuild(
            "extensions",
            listOf(":conformance-extension"),
        ),
    )

val declaredPaths = serviceBuilds.map(ServiceBuild::path).toSet()
val discoveredPaths =
    settingsDir
        .walkTopDown()
        .onEnter { directory ->
            directory == settingsDir || directory.name !in setOf(".gradle", "build", "build-logic")
        }
        .filter { it.name == "settings.gradle.kts" && it.parentFile != settingsDir }
        .map { it.parentFile.relativeTo(settingsDir).invariantSeparatorsPath }
        .toSet()
val missingPaths = declaredPaths - discoveredPaths
val unknownPaths = discoveredPaths - declaredPaths

check(missingPaths.isEmpty() && unknownPaths.isEmpty()) {
    buildString {
        append("Services composite inventory mismatch.")
        if (missingPaths.isNotEmpty()) append(" Missing roots: ${missingPaths.sorted().joinToString()}.")
        if (unknownPaths.isNotEmpty()) append(" Unknown roots: ${unknownPaths.sorted().joinToString()}.")
    }
}

gradle.beforeProject {
    if (path == ":") {
        extensions.extraProperties["serviceBuildProjects"] =
            serviceBuilds.associate { it.name to it.checkedProjects }
    }
}

serviceBuilds.forEach { serviceBuild ->
    includeBuild(serviceBuild.path) {
        name = serviceBuild.name
    }
}
