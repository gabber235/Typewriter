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

val loaderJar = layout.projectDirectory.file("loader/build/libs/typewriter-loader-1000.0.0.jar")
val standaloneDirectory = layout.buildDirectory.dir("development/standalone")

tasks.register<Exec>("devStandalone") {
    group = "development"
    description = "Runs the combined loader as a local standalone host."
    dependsOn(gradle.includedBuild("loader").task(":shadowJar"))
    inputs.file(loaderJar)
    outputs.dir(standaloneDirectory)
    doFirst {
        standaloneDirectory.get().asFile.mkdirs()
        workingDir(standaloneDirectory)
        commandLine(
            "${System.getProperty("java.home")}/bin/java",
            "-jar",
            loaderJar.asFile.absolutePath,
            standaloneDirectory.get().asFile.absolutePath,
        )
    }
}

tasks.register("devPaper") {
    group = "development"
    description = "Runs a disposable Paper server with the combined loader."
    dependsOn(gradle.includedBuild("dev-paper").task(":runServer"))
}

data class DevelopmentArtifact(
    val build: String,
    val task: String,
    val source: String,
    val publishedName: String,
)

val developmentArtifacts =
    listOf(
        DevelopmentArtifact("realm", ":jar", "realm/build/libs/realm-1000.0.0.jar", "typewritermc:realm__1.0.0__realm.jar"),
        DevelopmentArtifact(
            "engine",
            ":engine-panel:jar",
            "engine/runtimes/panel/build/libs/engine-panel-1000.0.0.jar",
            "typewritermc:panel__1.0.0__panel_engine.jar",
        ),
        DevelopmentArtifact(
            "engine",
            ":engine-paper:jar",
            "engine/runtimes/paper/build/libs/engine-paper-1000.0.0.jar",
            "typewritermc:paper__1.0.0__execution_engine.jar",
        ),
        DevelopmentArtifact(
            "engine",
            ":engine-conformance:jar",
            "engine/runtimes/conformance/build/libs/engine-conformance-1000.0.0.jar",
            "typewritermc:conformance__1.0.0__execution_engine.jar",
        ),
        DevelopmentArtifact(
            "engine",
            ":engine-minecraft:jar",
            "engine/layers/minecraft/build/libs/engine-minecraft-1000.0.0.jar",
            "typewritermc:minecraft__1.0.0__engine_layer.jar",
        ),
        DevelopmentArtifact(
            "engine",
            ":engine-conformance-base:jar",
            "engine/layers/conformance-base/build/libs/engine-conformance-base-1000.0.0.jar",
            "typewritermc:conformance-base__1.0.0__engine_layer.jar",
        ),
        DevelopmentArtifact(
            "engine",
            ":engine-conformance-composite:jar",
            "engine/layers/conformance-composite/build/libs/engine-conformance-composite-1000.0.0.jar",
            "typewritermc:conformance-composite__1.0.0__engine_layer.jar",
        ),
        DevelopmentArtifact(
            "extensions",
            ":conformance-extension:jar",
            "extensions/conformance/build/libs/conformance-extension-1000.0.0.jar",
            "typewritermc:conformance__1.0.0__extension.jar",
        ),
    )

tasks.register<Sync>("publishDevArtifacts") {
    group = "development"
    description = "Builds and publishes immutable development artifacts into a Realm import directory."
    into(layout.buildDirectory.dir("development/artifacts"))
    developmentArtifacts.forEach { artifact ->
        dependsOn(gradle.includedBuild(artifact.build).task(artifact.task))
        from(layout.projectDirectory.file(artifact.source)) {
            rename { artifact.publishedName }
        }
    }
}
