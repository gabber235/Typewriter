// The framework's Paper plugin: the step policy, the chat probe and Paper's side of the wire. It
// compiles against the patched server's own jars, so server internals are plain Java calls. Its
// rules with many cases have Kotlin unit tests, which need nothing from Paper.
plugins {
    id("com.typewritermc.basic-conventions")
}

// The patched server's jars are Java 25.
kotlin {
    jvmToolchain(25)
}

// Only the wire's own classes travel in the plugin jar; it needs nothing else at runtime, not even
// the Kotlin runtime its tests bring.
val bundledScope = configurations.dependencyScope("bundled")
val bundled = configurations.resolvable("bundledPath") { extendsFrom(bundledScope.get()) }

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
                        folder.asFile
                            .resolve(part)
                            .walk()
                            .filter { it.extension == "jar" }
                            .toList()
                    }
                }
            },
        ),
    )
    implementation(project(":playtest-wire")) { isTransitive = false }
    "bundled"(project(":playtest-wire")) { isTransitive = false }
}

// Paper loads the plugin as one jar, so the wire travels inside it.
tasks.jar {
    dependsOn(bundled)
    from(bundled.map { classpath -> classpath.map(::zipTree) })
}

configurations.consumable("playtestPlugin") {
    outgoing.artifact(tasks.jar)
}
