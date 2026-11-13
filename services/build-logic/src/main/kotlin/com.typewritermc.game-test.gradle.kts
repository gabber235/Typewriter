import com.typewritermc.buildlogic.servicesDirectory
import com.typewritermc.buildlogic.xtaskResults
import java.util.UUID

// Game requirements: tests in the `gameTest` source set run against real Minecraft clients on a
// stepped Paper, which the game pool boots. They are slow and need a desktop, so `check` leaves them
// out; `cargo xtask e2e game` runs them.
plugins {
    id("com.typewritermc.basic-conventions")
}

val gameTest = sourceSets.create("gameTest")

configurations.named(gameTest.implementationConfigurationName) { extendsFrom(configurations.getByName("testImplementation")) }
configurations.named(gameTest.runtimeOnlyConfigurationName) { extendsFrom(configurations.getByName("testRuntimeOnly")) }
kotlin.target.compilations.named("gameTest") { associateWith(kotlin.target.compilations.getByName("main")) }

kover {
    currentProject { instrumentation { disabledForTestTasks.add("gameTest") } }
}

/** A resolvable path to one part of the game another project builds. */
fun gamePart(
    name: String,
    path: String,
    configuration: String,
): NamedDomainObjectProvider<ResolvableConfiguration> {
    val scope =
        configurations.dependencyScope("${name}Scope") {
            dependencies.add(project.dependencies.project(mapOf("path" to path, "configuration" to configuration)))
        }
    return configurations.resolvable(name) { extendsFrom(scope.get()) }
}

val poolPart = gamePart("playtestPool", ":playtest-pool", "runtimeElements")
val paperPart = gamePart("playtestPaper", ":playtest-paper", "patchedPaper")
val agentPart = gamePart("playtestAgent", ":playtest-agent", "runtimeElements")
val pluginPart = gamePart("playtestPlugin", ":playtest-plugin", "playtestPlugin")
val clientLaunchPart = gamePart("playtestClientLaunch", ":playtest-client", "playtestClientLaunch")

/**
 * One run per build: every gameTest task of the build, in whichever project, reports into the same run
 * file, as their test JVMs share one pool.
 */
abstract class GameRun : BuildService<BuildServiceParameters.None> {
    val id: String = UUID.randomUUID().toString()
}

val gameRun = gradle.sharedServices.registerIfAbsent("playtestGameRun", GameRun::class) {}

/** The `-Dplaytest.*` properties the session reads and forwards to the pool it starts. */
abstract class GameParts : CommandLineArgumentProvider {
    @get:Classpath abstract val pool: ConfigurableFileCollection

    @get:InputFiles @get:PathSensitive(PathSensitivity.RELATIVE) abstract val paper: ConfigurableFileCollection

    @get:Classpath abstract val agent: ConfigurableFileCollection

    @get:Classpath abstract val plugin: ConfigurableFileCollection

    @get:InputFiles @get:PathSensitive(PathSensitivity.NONE) abstract val clientLaunch: ConfigurableFileCollection

    @get:Input abstract val java: Property<String>

    /** How many warm clients the pool keeps. */
    @get:Input abstract val clients: Property<Int>

    @get:Internal abstract val runId: Property<String>

    @get:Internal abstract val poolDir: Property<String>

    @get:Internal abstract val testRun: Property<String>

    override fun asArguments() =
        mapOf(
            "poolDir" to poolDir.get(),
            "poolClasspath" to pool.asPath,
            "java" to java.get(),
            "paper" to paper.singleFile.path,
            "agent" to agent.singleFile.path,
            "plugin" to plugin.singleFile.path,
            "clientLaunch" to clientLaunch.singleFile.path,
            "clients" to clients.get().toString(),
            "run" to runId.get(),
            "testRun" to testRun.get(),
        ).map { (name, value) -> "-Dplaytest.$name=$value" }
}

tasks.register<Test>("gameTest") {
    description = "Runs the game requirements against real Minecraft clients on a stepped Paper."
    group = "verification"
    testClassesDirs = gameTest.output.classesDirs
    classpath = gameTest.runtimeClasspath
    // The game's state lives outside Gradle's view, so a game run is never up to date.
    outputs.upToDateWhen { false }
    usesService(gameRun)
    jvmArgumentProviders +=
        objects.newInstance<GameParts>().apply {
            pool.from(poolPart)
            paper.from(paperPart)
            agent.from(agentPart)
            plugin.from(pluginPart)
            clientLaunch.from(clientLaunchPart)
            java.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) }.map { it.executablePath.asFile.path })
            // `-Pplaytest.clients=1` runs the suite on a pool of one client.
            clients.set(providers.gradleProperty("playtest.clients").map(String::toInt).orElse(4))
            runId.set(gameRun.map { it.id })
            poolDir.set(servicesDirectory.resolve("build/playtest/pool").path)
            testRun.set(xtaskResults.resolve("game/test_run.json").path)
        }
}
