rootProject.name = "services"

data class ServiceBuild(
    val name: String,
    val path: String,
    val checkedProjects: List<String>,
)

val serviceBuilds =
    listOf(
        ServiceBuild("service-utils", "libs/service-utils", listOf(":")),
        ServiceBuild(
            "service-telemetry",
            "libs/service-telemetry",
            listOf(
                ":service-telemetry-core",
                ":service-telemetry-console",
                ":service-telemetry-koin",
                ":service-telemetry-testing",
            ),
        ),
        ServiceBuild(
            "service-http",
            "libs/service-http",
            listOf(":service-http-core", ":service-http-jdk", ":service-http-testing"),
        ),
        ServiceBuild(
            "service-communicator",
            "libs/service-communicator",
            listOf(
                ":service-communicator-core",
                ":service-communicator-nats",
                ":service-communicator-skir",
                ":service-communicator-koin",
                ":service-communicator-testing",
            ),
        ),
        ServiceBuild(
            "service-registrar",
            "libs/service-registrar",
            listOf(
                ":service-registrar-core",
                ":service-registrar-runtime",
                ":service-registrar-storage-file",
                ":service-registrar-console",
                ":service-registrar-koin",
                ":service-registrar-testing",
            ),
        ),
        ServiceBuild("realm", "realm", listOf(":")),
    )

val declaredPaths = serviceBuilds.map(ServiceBuild::path).toSet()
val discoveredPaths =
    buildSet {
        file("libs").listFiles()
            ?.filter { it.resolve("settings.gradle.kts").isFile }
            ?.mapTo(this) { "libs/${it.name}" }
        settingsDir.listFiles()
            ?.filter { it.isDirectory && it.name != "build-logic" && it.name != "libs" }
            ?.filter { it.resolve("settings.gradle.kts").isFile }
            ?.mapTo(this) { it.name }
    }
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
