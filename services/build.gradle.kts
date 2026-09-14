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
val manualArtifactTarget = artifactInboxRoot.map { it.resolve("manual") }

tasks.register("assembleDevelopmentArtifacts") {
    val developmentArtifactTasks =
        listOf(
            project(":realm").tasks.named<Jar>("shadowJar"),
            project(":engine-paper").tasks.named<Jar>("shadowJar"),
            project(":engine-panel").tasks.named<Jar>("shadowJar"),
            project(":basic-extension").tasks.named<Jar>("jar"),
            project(":conformance-extension").tasks.named<Jar>("jar"),
        )
    val developmentArtifactFiles = developmentArtifactTasks.map { it.flatMap(Jar::getArchiveFile) }
    val publishedArtifactFiles =
        developmentArtifactFiles.map { artifact ->
            manualArtifactTarget.map { target -> target.resolve(artifact.get().asFile.name) }
        }

    group = "typewriter"
    description = "Builds development artifacts and publishes complete JARs into an artifact inbox."
    dependsOn(developmentArtifactTasks)
    inputs.files(developmentArtifactFiles)
    outputs.files(publishedArtifactFiles)
    doLast {
        val sources = developmentArtifactFiles.map { it.get().asFile }
        val target = manualArtifactTarget.get().also(File::mkdirs)
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
