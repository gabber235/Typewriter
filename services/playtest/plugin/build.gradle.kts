// The framework's Paper plugin: the step policy, the chat probe and Paper's side of the wire. It
// compiles against the patched server's own jars, so server internals are plain Java calls.
plugins {
    java
}

repositories {
    mavenCentral()
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(25))
}

val patchedPaperScope = configurations.dependencyScope("patchedPaper")
val patchedPaper = configurations.resolvable("patchedPaperPath") { extendsFrom(patchedPaperScope.get()) }

dependencies {
    "patchedPaper"(project(":playtest-paper", "patchedPaper"))
    compileOnly(project(":playtest-agent"))
    compileOnly(
        files(
            patchedPaper.flatMap { it.elements }.map { folders ->
                folders.flatMap { folder ->
                    listOf("versions", "libraries").flatMap { part ->
                        folder.asFile.resolve(part).walk().filter { it.extension == "jar" }.toList()
                    }
                }
            },
        ),
    )
    // Only the wire's own classes travel in the plugin jar; it needs nothing else at runtime.
    implementation(project(":playtest-wire")) { isTransitive = false }
}

// Paper loads the plugin as one jar, so the wire travels inside it.
tasks.jar {
    dependsOn(configurations.runtimeClasspath)
    from(configurations.runtimeClasspath.map { classpath -> classpath.map(::zipTree) })
}

configurations.consumable("playtestPlugin") {
    outgoing.artifact(tasks.jar)
}
