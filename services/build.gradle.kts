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

val publishDevArtifacts =
    tasks.register("publishDevArtifacts") {
        group = "development"
        description = "Builds and publishes all runtime artifacts for local development."
        dependsOn(gradle.includedBuild("realm").task(":publishDevArtifacts"))
        dependsOn(gradle.includedBuild("engine").task(":publishDevArtifacts"))
        dependsOn(gradle.includedBuild("extensions").task(":publishDevArtifacts"))
    }

val loaderRuntime = configurations.create("loaderRuntime") {
    isTransitive = false
}
dependencies.add(loaderRuntime.name, "com.typewritermc:loader:development")

tasks.register<JavaExec>("devStandalone") {
    group = "development"
    description = "Runs the combined loader as a local standalone host."
    dependsOn(publishDevArtifacts)
    classpath(loaderRuntime)
    mainClass.set("com.typewritermc.loader.standalone.StandaloneLoader")
    args(layout.buildDirectory.dir("development/standalone").get().asFile.absolutePath)
}

tasks.register<GradleBuild>("devPaper") {
    group = "development"
    description = "Runs a disposable Paper server with the combined loader."
    dependsOn(publishDevArtifacts)
    dir = layout.projectDirectory.dir("engine").asFile
    tasks = listOf(":engine-paper:runServer")
}
