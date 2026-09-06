import org.gradle.api.tasks.bundling.Jar

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

val loaderProjects =
    listOf(
        ":loader-api",
        ":loader-core",
        ":loader-standalone",
        ":loader-paper",
        ":loader-distribution",
    )

loaderProjects.map(::project).forEach { it.version = "1000.0.0" }

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
val developmentArtifactTarget = artifactInboxRoot.map { it.resolve("development") }

tasks.register("assembleDevelopmentArtifacts") {
    val developmentArtifactTasks =
        listOf(
            project(":realm").tasks.named<Jar>("shadowJar"),
            project(":engine-paper").tasks.named<Jar>("shadowJar"),
            project(":engine-panel").tasks.named<Jar>("shadowJar"),
            project(":conformance-extension").tasks.named<Jar>("jar"),
        )
    val developmentArtifactFiles = developmentArtifactTasks.map { it.flatMap(Jar::getArchiveFile) }

    group = "typewriter"
    description = "Builds development artifacts and publishes complete JARs into an artifact inbox."
    dependsOn(developmentArtifactTasks)
    inputs.files(developmentArtifactFiles)
    outputs.dir(developmentArtifactTarget)
    doLast {
        val sources = developmentArtifactFiles.map { it.get().asFile }
        val target = developmentArtifactTarget.get().also(File::mkdirs)
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
