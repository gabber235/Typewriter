// The framework's Paper plugin: the step policy, the chat probe and Paper's side of the wire. It
// compiles against the patched server's own jars, so server internals are plain Java calls. Its
// rules with many cases have Kotlin unit tests, which need nothing from Paper.
plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

// The patched server's jars are Java 25.
kotlin {
    jvmToolchain(25)
}

val patchedPaperScope = configurations.dependencyScope("patchedPaper")
val patchedPaper = configurations.resolvable("patchedPaperPath") { extendsFrom(patchedPaperScope.get()) }

dependencies {
    "patchedPaper"(project(":playtest-paper", "patchedPaper"))
    compileOnly(project(":playtest-agent"))
    // The JaCoCo agent the pool starts Paper with; the plugin reads its counts through the agent's own API.
    compileOnly(variantOf(libs.jacoco.agent) { classifier("runtime") })
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
    implementation(project(":playtest-wire"))
}

// Paper loads the plugin as one jar and provides none of what the wire runs on, so the jar carries the
// plugin's whole runtime classpath: the wire, the Kotlin standard library, and the Skir runtime its
// generated messages are read and written with (skir-client with okio, kotlinx serialization and
// coroutines). Of the generated protocol only the harness contracts travel, since the wire declares its
// messages there and the plugin uses no other context. Every bundled jar brings its own manifest and
// module descriptor, which a plain jar on Paper's plugin class loader neither needs nor may repeat.
tasks.jar {
    val runtime = configurations.runtimeClasspath
    dependsOn(runtime)
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    from(runtime.map { classpath -> classpath.map(::zipTree) }) {
        exclude("META-INF/MANIFEST.MF", "module-info.class", "META-INF/versions/*/module-info.class")
        exclude { it.path.startsWith("skirout/") && !it.path.startsWith("skirout/harness/") }
    }
}

configurations.consumable("playtestPlugin") {
    outgoing.artifact(tasks.jar)
}

// The JaCoCo agent the pool starts every Paper with, the one whose counts the plugin reads.
val coverageAgent = configurations.dependencyScope("coverageAgent")
dependencies { "coverageAgent"(variantOf(libs.jacoco.agent) { classifier("runtime") }) }
configurations.consumable("playtestCoverageAgent") { extendsFrom(coverageAgent.get()) }
