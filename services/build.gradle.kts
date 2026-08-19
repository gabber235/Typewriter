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
