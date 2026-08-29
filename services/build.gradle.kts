@Suppress("UNCHECKED_CAST")
val serviceBuildProjects = extra["serviceBuildProjects"] as Map<String, List<String>>

fun includedTasks(taskName: String) =
    serviceBuildProjects.flatMap { (buildName, projectPaths) ->
        projectPaths.map { projectPath ->
            val separator = if (projectPath == ":") "" else ":"
            gradle.includedBuild(buildName).task("$projectPath$separator$taskName")
        }
    }

tasks.register("check") {
    group = "verification"
    description = "Runs checks for every service Gradle root."
    dependsOn(includedTasks("check"))
}

tasks.register("ktlintCheck") {
    group = "verification"
    description = "Runs Kotlin formatting checks for every service Gradle root."
    dependsOn(includedTasks("ktlintCheck"))
}

val artifactInboxRoot =
    providers.gradleProperty("typewriterArtifactInbox").map(::file).orElse(
        layout.buildDirectory.dir("development/artifacts/inbox").map { it.asFile },
    )

tasks.register("assembleDevelopmentArtifacts") {
    group = "typewriter"
    description = "Builds development artifacts and publishes complete JARs into an artifact inbox."
    dependsOn(
        gradle.includedBuild("realm").task(":shadowJar"),
        gradle.includedBuild("engine").task(":engine-paper:shadowJar"),
        gradle.includedBuild("engine").task(":engine-panel:shadowJar"),
        gradle.includedBuild("extensions").task(":conformance-extension:jar"),
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
