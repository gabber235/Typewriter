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
val coverageAgentPart = gamePart("playtestCoverageAgent", ":playtest-plugin", "playtestCoverageAgent")

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

    @get:Classpath abstract val coverageAgent: ConfigurableFileCollection

    @get:InputFiles @get:PathSensitive(PathSensitivity.NONE) abstract val clientLaunch: ConfigurableFileCollection

    @get:Input abstract val java: Property<String>

    /** How many warm clients the pool keeps. */
    @get:Input abstract val clients: Property<Int>

    @get:Internal abstract val runId: Property<String>

    @get:Internal abstract val poolDir: Property<String>

    @get:Internal abstract val testRun: Property<String>

    /** The run's logs folder: the pool's, every Paper's and every client's. */
    @get:Internal abstract val logs: Property<String>

    /** Attempts of each requirement; absent, a failed attempt runs again up to 4 in total. */
    @get:Internal abstract val repeat: Property<String>

    /** The requirements the quarantine holds: they run once and never block. */
    @get:Internal abstract val quarantine: Property<String>

    /** The file of lines the change added; a requirement that covered one reruns in demo mode. */
    @get:Internal abstract val touched: Property<String>

    /** The repository root, which golden paths start from. */
    @get:Internal abstract val root: Property<String>

    /** This project's golden files, from the repository root. */
    @get:Internal abstract val goldens: Property<String>

    /** The local golden images, each named by the hash of its frame. */
    @get:Internal abstract val goldenImages: Property<String>

    /** The Mesa release devenv ships, which the pinned renderer draws with. */
    @get:Internal abstract val mesa: Property<String>

    /** Whether this machine is the pinned runner, where a frame from another renderer fails its golden. */
    @get:Internal abstract val pinnedRunner: Property<Boolean>

    override fun asArguments() =
        (
            mapOf(
                "poolDir" to poolDir.get(),
                "poolClasspath" to pool.asPath,
                "java" to java.get(),
                "paper" to paper.singleFile.path,
                "agent" to agent.singleFile.path,
                "plugin" to plugin.singleFile.path,
                "coverageAgent" to coverageAgent.singleFile.path,
                "clientLaunch" to clientLaunch.singleFile.path,
                "clients" to clients.get().toString(),
                "run" to runId.get(),
                "testRun" to testRun.get(),
                "logs" to logs.get(),
                "root" to root.get(),
                "goldens" to goldens.get(),
                "goldenImages" to goldenImages.get(),
                "mesa" to mesa.get(),
                "pinnedRunner" to pinnedRunner.get().toString(),
            ) +
                listOf("repeat" to repeat, "quarantine" to quarantine, "touched" to touched)
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
    // `cargo xtask e2e game --only` selects across every game module, so a module may hold none of
    // the selected requirements. Whether a selected id matched nothing is the whole run's question,
    // and xtask's selection check (`results::selection_matches`) answers it from the run file.
    filter.isFailOnNoMatchingTests = false
    usesService(gameRun)
    jvmArgumentProviders +=
        objects.newInstance<GameParts>().apply {
            pool.from(poolPart)
            paper.from(paperPart)
            agent.from(agentPart)
            plugin.from(pluginPart)
            coverageAgent.from(coverageAgentPart)
            clientLaunch.from(clientLaunchPart)
            java.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) }.map { it.executablePath.asFile.path })
            // `-Pplaytest.clients=1` runs the suite on a pool of one client.
            clients.set(providers.gradleProperty("playtest.clients").map(String::toInt).orElse(4))
            runId.set(gameRun.map { it.id })
            poolDir.set(servicesDirectory.resolve("build/playtest/pool").path)
            // `cargo xtask e2e game` names the run file it gates on; other runs keep theirs in the build.
            testRun.set(providers.gradleProperty("playtest.testRun").orElse(servicesDirectory.resolve("build/playtest/test_run.json").path))
            // It names a logs folder of the run's own too; other runs share one in the build.
            logs.set(providers.gradleProperty("playtest.logs").orElse(servicesDirectory.resolve("build/playtest/logs").path))
            repeat.set(providers.gradleProperty("playtest.repeat"))
            quarantine.set(providers.gradleProperty("playtest.quarantine"))
            // `cargo xtask e2e game` writes it against the merge base with the default branch.
            touched.set(providers.gradleProperty("playtest.touched"))
            root.set(repositoryRoot.path)
            goldens.set(projectDir.resolve("src/gameTest/goldens").relativeTo(repositoryRoot).invariantSeparatorsPath)
            // `cargo xtask goldens approve` keeps each approved frame here; a run diffs against it.
            goldenImages.set(servicesDirectory.resolve("build/playtest/goldens").path)
            // devenv.nix exports the Mesa it ships, so the pin moves with nixpkgs.
            mesa.set(providers.environmentVariable("PLAYTEST_MESA"))
            // CI's game job runs on the pinned runner and says so; other machines only note frames they cannot check.
            pinnedRunner.set(providers.environmentVariable("PLAYTEST_PINNED_RUNNER").map { it == "1" }.orElse(false))
        }
}

// `cargo xtask e2e game` builds everything gameTest runs in a Gradle of its own first, so the Kotlin
// compile daemons end with that Gradle and hold no memory while the suite runs.
tasks.register("gameTestBuild") {
    description = "Builds everything gameTest runs, and runs nothing."
    group = "build"
    dependsOn(gameTest.output, gameTest.runtimeClasspath, poolPart, paperPart, agentPart, pluginPart, coverageAgentPart, clientLaunchPart)
}
