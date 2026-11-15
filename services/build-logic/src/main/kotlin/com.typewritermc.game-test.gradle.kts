import com.typewritermc.buildlogic.repositoryRoot
import com.typewritermc.buildlogic.servicesDirectory
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

    /** The requirements the run runs, by id or test id, comma separated; every one when absent. */
    @get:Internal abstract val only: Property<String>

    /** Attempts of each requirement; absent, a failed attempt runs again up to 4 in total. */
    @get:Internal abstract val repeat: Property<String>

    /** The requirements the quarantine holds: they run once and never block. */
    @get:Internal abstract val quarantine: Property<String>

    /** The repository root, which golden paths start from. */
    @get:Internal abstract val root: Property<String>

    /** This project's golden files, from the repository root. */
    @get:Internal abstract val goldens: Property<String>

    /** The local golden images, each named by the hash of its frame. */
    @get:Internal abstract val goldenImages: Property<String>

    override fun asArguments() =
        (
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
                "root" to root.get(),
                "goldens" to goldens.get(),
                "goldenImages" to goldenImages.get(),
            ) +
                listOf("only" to only, "repeat" to repeat, "quarantine" to quarantine)
                    .mapNotNull { (name, value) -> value.orNull?.let { name to it } }
        ).map { (name, value) -> "-Dplaytest.$name=$value" }
}

tasks.register<Test>("gameTest") {
    description = "Runs the game requirements against real Minecraft clients on a stepped Paper."
    group = "verification"
    testClassesDirs = gameTest.output.classesDirs
    classpath = gameTest.runtimeClasspath
    // The game's state lives outside Gradle's view, so a game run is never up to date.
    outputs.upToDateWhen { false }
    // A run that selects requirements may select none of this project's; `cargo xtask e2e game` fails a
    // selected id that matches no case of the run file instead.
    failOnNoDiscoveredTests.set(providers.gradleProperty("playtest.only").map { false }.orElse(true))
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
            // `cargo xtask e2e game` names the run file it gates on; other runs keep theirs in the build.
            testRun.set(providers.gradleProperty("playtest.testRun").orElse(servicesDirectory.resolve("build/playtest/test_run.json").path))
            only.set(providers.gradleProperty("playtest.only"))
            repeat.set(providers.gradleProperty("playtest.repeat"))
            quarantine.set(providers.gradleProperty("playtest.quarantine"))
            root.set(repositoryRoot.path)
            goldens.set(projectDir.resolve("src/gameTest/goldens").relativeTo(repositoryRoot).invariantSeparatorsPath)
            // `cargo xtask goldens approve` keeps each approved frame here; a run diffs against it.
            goldenImages.set(servicesDirectory.resolve("build/playtest/goldens").path)
        }
}
