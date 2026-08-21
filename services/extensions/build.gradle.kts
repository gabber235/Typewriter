subprojects {
    version = "1000.0.0"
}

val publishDevArtifacts = tasks.register("publishDevArtifacts") {
    group = "development"
    description = "Publishes all extension artifacts for local development."
}

subprojects {
    pluginManager.withPlugin("com.typewritermc.imprint") {
        val artifactTaskPath = "$path:publishDevArtifact"
        publishDevArtifacts.configure { dependsOn(artifactTaskPath) }
    }
}
