import com.typewritermc.buildlogic.realmDatabaseCredentials
import com.typewritermc.playtest.launch.HeapShare
import xyz.jpenilla.runpaper.task.RunServer
import java.nio.file.Files
import java.nio.file.StandardCopyOption

plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("xyz.jpenilla.run-paper")
    id("com.typewritermc.game-test")
    id("com.typewritermc.paper-api")
    `java-library`
    `java-test-fixtures`
}

val loaderPlugin =
    configurations.create("loaderPlugin") {
        isTransitive = false
    }
val paperRunDirectory = rootProject.layout.projectDirectory.dir("./build/development/paper")
val paperManualInbox = paperRunDirectory.dir("plugins/Typewriter/artifacts/inbox/manual")
val assembleDevelopmentArtifacts = rootProject.tasks.named("assembleDevelopmentArtifacts")
val stagedPaperArtifactFiles =
    assembleDevelopmentArtifacts.map { task ->
        task.outputs.files.map { artifact -> paperManualInbox.file(artifact.name) }
    }
val stagePaperArtifacts =
    tasks.register("stagePaperArtifacts") {
        group = "typewriter"
        description = "Stages canonical artifacts in the local Paper loader inbox."
        dependsOn(assembleDevelopmentArtifacts)
        inputs.files(assembleDevelopmentArtifacts.map { it.outputs.files })
        outputs.files(stagedPaperArtifactFiles)
        doLast {
            val target = paperManualInbox.asFile.also(File::mkdirs)
            assembleDevelopmentArtifacts.get().outputs.files.forEach { source ->
                val temporary = target.resolve(".${source.name}.partial")
                source.copyTo(temporary, overwrite = true)
                Files.move(
                    temporary.toPath(),
                    target.resolve(source.name).toPath(),
                    StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING,
                )
            }
        }
    }

dependencies {
    // Paper and the loader plugin are present wherever a Paper engine runs; the engine reaches Paper through them, and
    // every extension's Paper part compiles against the same Paper API through this engine.
    compileOnlyApi(libs.paper.api)
    compileOnly(project(":loader-paper"))
    imprintEngineCore(project(":engine-core"))
    imprintHostApi(project(":loader-api"))
    imprintPlatformApi(project(":typewriter-api"))
    loaderPlugin(project(":loader-distribution"))
    "gameTestImplementation"(project(":playtest"))
    // The event requirements write content of the basic extension's entries and events: its JAR, since its classes live
    // in its source parts rather than in main.
    "gameTestImplementation"(project(":basic-extension")) {
        attributes { attribute(LibraryElements.LIBRARY_ELEMENTS_ATTRIBUTE, objects.named(LibraryElements.JAR)) }
    }
    // The stack observer the game requirements read the topology and the sessions bucket through.
    testFixturesImplementation(project(":messaging"))
    testFixturesImplementation(project(":protocol-transport"))
    testFixturesApi(project(":engine-core"))
    testFixturesApi(project(":typewriter-api"))
    // The stack author plans setups with the Realm's own planner and declares the content a requirement owns.
    testFixturesApi(testFixtures(project(":realm")))
    // It reads the artifacts the stack's Realm host committed, so its planner loads exactly what that Realm loads.
    testFixturesImplementation(project(":loader-core"))
    testFixturesImplementation("com.typewritermc:imprint-archive")
    testFixturesApi(project(":playtest"))
}

/** A value of the stack `cargo xtask e2e game` runs the game suite in, which it hands Gradle. */
fun stackValue(name: String): Provider<String> =
    providers.environmentVariable(name).orElse(
        provider {
            throw GradleException("$name is not set: the game suite runs inside the stack `cargo xtask e2e game` starts")
        },
    )

// Every game Paper runs the Typewriter loader against the stack. Each slot's loader writes its
// registration token where the stack's engine binder waits for that slot, and keeps the identity it
// was bound with, so every own Paper of a slot is the same engine host.
gamePaper {
    pluginJars.from(loaderPlugin)
    environment.put("TYPEWRITER_CONFIG_FILE", stackValue("TYPEWRITER_CONFIG_FILE"))
    (0..HeapShare.OWN_PAPERS).forEach { slot ->
        slot(slot) {
            environment.put(
                "TYPEWRITER_REGISTRATION_TOKEN_FILE",
                stackValue("STACK_GAME_ENGINES").map { "$it/$slot/registration-token" },
            )
        }
    }
    keptPerSlot.add("plugins/Typewriter/state")
    // Counts chain work as player work, drops a wiped player's chains, and reports what the engine applied.
    typewriterExtensions.from(project(":playtest-bridge"))
}

runPaper {
    disablePluginJarDetection()
}

private fun RunServer.configurePaperRuntime(configurationFile: String) {
    minecraftVersion(libs.versions.minecraft.get())
    build(
        libs.versions.paper.build
            .get()
            .toInt(),
    )
    javaLauncher.set(
        javaToolchains.launcherFor {
            languageVersion.set(JavaLanguageVersion.of(25))
        },
    )
    runDirectory.set(paperRunDirectory)
    pluginJars.from(loaderPlugin)
    dependsOn(stagePaperArtifacts)
    environment(
        "TYPEWRITER_CONFIG_FILE",
        rootProject.layout.projectDirectory
            .file("runtime/config/$configurationFile")
            .asFile.absolutePath,
    )
}

tasks.runServer {
    configurePaperRuntime("local.properties")
}

private val realmDatabaseCredentials = providers.realmDatabaseCredentials()

tasks.register<RunServer>("runServerKubernetes") {
    group = "run paper"
    description = "Run a Paper server using the local Kubernetes Realm database."
    configurePaperRuntime("local-kubernetes.properties")
    doFirst {
        val credentials = realmDatabaseCredentials.get()
        environment("REALM_DB_USERNAME", credentials.username)
        environment("REALM_DB_PASSWORD", credentials.password)
    }
}

typewriter {
    engine {
        id = "typewritermc:paper"
        version = "1.0.0"
        hostApi = "^1"
        implements {
            capability(project(":engine-minecraft"), version = "1.0.0")
        }
    }
}
