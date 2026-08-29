plugins {
    base
}

val internalPlatformProjects =
    listOf(
        ":messaging",
        ":file-transfer",
        ":telemetry",
    )

internalPlatformProjects.map(::project).forEach { it.version = "1000.0.0" }

subprojects.forEach { serviceProject ->
    serviceProject.pluginManager.withPlugin("com.typewritermc.imprint") {
        serviceProject.dependencies.add("imprintProcessors", project(":typewriter-codegen"))
    }
}

tasks.named("check") {
    dependsOn(subprojects.map { "${it.path}:check" })
}

tasks.register("ktlintCheck") {
    group = "verification"
    description = "Runs Kotlin formatting checks for every service project."
    dependsOn(subprojects.map { "${it.path}:ktlintCheck" })
}

val artifactInboxRoot =
    providers.gradleProperty("typewriterArtifactInbox").map(::file).orElse(
        layout.buildDirectory.dir("development/artifacts/inbox").map { it.asFile },
    )

tasks.register("assembleDevelopmentArtifacts") {
    group = "typewriter"
    description = "Builds development artifacts and publishes complete JARs into an artifact inbox."
    dependsOn(
        project(":realm").tasks.named("shadowJar"),
        project(":engine-paper").tasks.named("shadowJar"),
        project(":engine-panel").tasks.named("shadowJar"),
        project(":conformance-extension").tasks.named("jar"),
    )
    outputs.dir(artifactInboxRoot)
    doLast {
        val sources =
            listOf(
                file("runtime/realm/build/libs"),
                file("runtime/engine/runtimes/paper/build/libs"),
                file("runtime/engine/runtimes/panel/build/libs"),
                file("extensions/conformance/build/libs"),
            ).map { directory ->
                directory.listFiles()
                    ?.filter { it.isFile && it.extension == "jar" && !it.name.contains("plain") }
                    ?.maxByOrNull(File::lastModified)
                    ?: error("Expected a canonical development artifact in $directory.")
            }
        val target = artifactInboxRoot.get().resolve("development").also(File::mkdirs)
        val expectedNames = sources.mapTo(mutableSetOf(), File::getName)
        target.listFiles()
            ?.filter { it.isFile && it.extension == "jar" && it.name !in expectedNames }
            ?.forEach { stale -> check(stale.delete()) { "Could not remove stale development artifact ${stale.name}." } }
        sources.forEach { source ->
            val temporary = target.resolve(".${source.name}.partial")
            source.copyTo(temporary, overwrite = true)
            java.nio.file.Files.move(
                temporary.toPath(),
                target.resolve(source.name).toPath(),
                java.nio.file.StandardCopyOption.ATOMIC_MOVE,
                java.nio.file.StandardCopyOption.REPLACE_EXISTING,
            )
        }
    }
}
